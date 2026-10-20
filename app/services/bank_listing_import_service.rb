require "open-uri"

# Replaces the bank finder's listings with the current NDBN and Alliance for Period Supplies
# directories. Run weekly by BankListingImportJob, or by hand with `bin/rails bank_listings:import`.
#
# Both directories are Google My Maps, and a My Map exports its points as KML, so this reads the
# export rather than scraping a page. Each point has a name, a headquarters city and state, and a
# website -- no address -- and the city is placed with CensusLocation.
#
# **It never replaces a good list with a bad one.** If either export fails to download or parse,
# or comes back with less than half the banks it had last time, nothing is written and the
# result says why: a map that has been moved or emptied would otherwise empty the finder, and
# nobody would notice until a visitor did. See ADR 0014.
class BankListingImportService
  SOURCES = {
    diapers: "https://www.google.com/maps/d/kml?mid=1nqyZcnNPL_M0fXbaILWlmZVg6TU&forcekml=1",
    period_supplies: "https://www.google.com/maps/d/kml?mid=1oYKlaD-EFkB6vtBDDnM-D9F80cXZmtsY&forcekml=1"
  }.freeze

  # Misspelled in the source. Corrected in what the finder shows, as well as where it looks.
  CITY_CORRECTIONS = {
    ["Worchester", "MA"] => "Worcester", ["Winsten-Salem", "NC"] => "Winston-Salem",
    ["Lobard", "IL"] => "Lombard", ["Mellville", "NY"] => "Melville",
    ["Owatonnaq", "MN"] => "Owatonna"
  }.freeze

  # Real places the Census files do not name -- neighborhoods, villages, unincorporated
  # communities and counties -- mapped to the nearest one they do. Only used to place the bank;
  # the finder still shows the city the bank gives. With CITY_CORRECTIONS, measured on
  # 2026-10-19 as every listing the lookup could not otherwise place.
  CITY_ALIASES = {
    ["Bronx", "NY"] => "New York", ["New York City", "NY"] => "New York",
    ["Hyannis", "MA"] => "Barnstable Town", ["Kamuela", "HI"] => "Waimea",
    ["North Hills", "CA"] => "Los Angeles", ["Cordova", "TN"] => "Memphis",
    ["Elko", "MN"] => "Elko New Market",
    ["Millersville", "MD"] => "Severna Park", ["Chesterfield", "VA"] => "Chester",
    ["Rockingham", "VA"] => "Harrisonburg", ["Middlesex", "MA"] => "Cambridge",
    ["St. Charles", "MD"] => "Waldorf", ["Wilmer", "AL"] => "Semmes"
  }.freeze

  # The two exports cut down to a few invented banks, in the real exports' shape: the dev seeds
  # and the specs import these instead of downloading.
  SAMPLE_DIR = Rails.root.join("db/seed_data/bank_listings")
  SAMPLE_FETCH = lambda do |url|
    File.read(SAMPLE_DIR.join({SOURCES[:diapers] => "ndbn.kml", SOURCES[:period_supplies] => "apsp.kml"}.fetch(url)))
  end

  # The smallest share of last week's listings an export may come back with.
  MINIMUM_SHARE = 0.5

  Result = Data.define(:imported, :unplaced, :error) do
    def success? = error.nil?
  end

  def self.call(...) = new(...).call

  # `fetch` takes a URL and returns its body; specs pass one that reads a fixture.
  def initialize(fetch: ->(url) { URI.parse(url).open(read_timeout: 30, &:read) })
    @fetch = fetch
  end

  def call
    listings = {}
    SOURCES.each do |supply, url|
      rows = parse(fetch(url, supply))
      check_count!(supply, rows.size)
      rows.each { |row| merge(listings, row, supply) }
    end

    unplaced = listings.values.reject { |l| place(l) }
    replace(listings.values)
    Result.new(imported: listings.size, unplaced: unplaced.map { |l| "#{l[:name]} (#{l[:city]}, #{l[:state]})" }, error: nil)
  rescue ImportError => e
    Rails.logger.error("[BankListingImportService] #{e.message}")
    Result.new(imported: 0, unplaced: [], error: e.message)
  end

  class ImportError < StandardError; end

  private

  def fetch(url, supply)
    @fetch.call(url)
  rescue => e
    raise ImportError, "Could not download the #{supply.to_s.humanize(capitalize: false)} directory (#{e.class}: #{e.message})."
  end

  # Every point in the export, whatever folder it is in. The three folders across the two maps
  # use three sets of field names for the same four things.
  def parse(kml)
    doc = Nokogiri::XML(kml)
    doc.remove_namespaces!
    doc.xpath("//Placemark").filter_map do |placemark|
      data = placemark.xpath(".//Data").to_h do |d|
        [d["name"].to_s.downcase.strip.delete_suffix(":").strip, d.at_xpath("value")&.text.to_s.strip]
      end
      name = data["organization"].presence || placemark.at_xpath("name")&.text.to_s.strip
      city = data.values_at("city (headquarters)", "headquarter city", "city").compact_blank.first
      state = CensusLocation.state_code(data.values_at("state", "st").compact_blank.first)
      next if name.blank? || city.blank? || state.blank?

      city = city.squish
      # The Alliance's NDBN folder is in capitals ("AUSTIN"). Not `titleize`, which drops the
      # hyphen from Winston-Salem.
      city = city.downcase.gsub(/\b[a-z]/, &:upcase) if city == city.upcase
      city = CITY_CORRECTIONS.fetch([city, state], city)
      {name: name.squish, city: city, state: state, website: data["website"].presence,
       ndbn_member_id: data["member id"].to_s[/\A\d+/]&.to_i}
    end
  end

  def check_count!(supply, count)
    previous = BankListing.where(supply => true).count
    label = supply.to_s.humanize(capitalize: false)
    raise ImportError, "The #{label} directory had no banks in it." if count.zero?
    return if previous.zero? || count >= previous * MINIMUM_SHARE
    raise ImportError, "The #{label} directory has #{count} banks, down from #{previous}. " \
      "Kept last week's list in case the map has moved or been emptied."
  end

  # A bank in both directories is one listing. Matched on the normalized name: 90 of the 194
  # period supply programs are NDBN members, and their names agree.
  def merge(listings, row, supply)
    key = CensusLocation.key_for(row[:name])
    listing = listings[key] ||= row.merge(name_key: key, diapers: false, period_supplies: false)
    listing[supply] = true
    listing[:website] ||= row[:website]
    # Only the NDBN directory's member IDs are NDBN member IDs.
    listing[:ndbn_member_id] = row[:ndbn_member_id] if supply == :diapers
  end

  def place(listing)
    city = CITY_ALIASES.fetch([listing[:city], listing[:state]], listing[:city])
    point = CensusLocation.find_city(city, listing[:state])
    listing[:latitude] = point&.latitude
    listing[:longitude] = point&.longitude
    point
  end

  def replace(listings)
    columns = %i[name name_key city state website diapers period_supplies ndbn_member_id latitude longitude]
    rows = listings.map { |l| l.slice(*columns) }
    # upsert_all sets created_at and updated_at itself.
    BankListing.transaction do
      BankListing.where.not(name_key: rows.pluck(:name_key)).delete_all
      BankListing.upsert_all(rows, unique_by: :name_key, update_only: columns - [:name_key])
    end
  end
end
