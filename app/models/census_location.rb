# == Schema Information
#
# Table name: census_locations
#
#  id        :bigint           not null, primary key
#  kind      :string           not null
#  latitude  :float            not null
#  longitude :float            not null
#  name      :string           not null
#  name_key  :string           not null
#  state     :string
#
require "csv"
require "zlib"

# A place a visitor can search from, with the point the bank finder measures distance from.
#
# Loaded from the US Census Bureau's Gazetteer files (public domain), not from a geocoding
# service: what a visitor types never leaves the app, there is no API key or rate limit, and the
# 347 banks in the directories only give a city and state, so a street-level geocoder would be
# precision the data cannot use. See ADR 0014.
#
# Three kinds, tried in this order for a city:
#   place               incorporated cities and towns, and census-designated places
#   county_subdivision  townships and New England towns -- Montclair NJ and West Stockbridge MA are not
#                       places, so a city lookup that stopped at places missed them
#   zip                 ZIP Code Tabulation Areas, keyed by the five digits, with no state
#
# `bin/rails census_locations:build` makes `lib/assets/census_locations.csv.gz` from the Census
# files, and `bin/rails db:load_census_locations` loads it.
class CensusLocation < ApplicationRecord
  KINDS = %w[place county_subdivision zip].freeze

  STATE_NAMES = {
    "alabama" => "AL", "alaska" => "AK", "arizona" => "AZ", "arkansas" => "AR",
    "california" => "CA", "colorado" => "CO", "connecticut" => "CT", "delaware" => "DE",
    "district of columbia" => "DC", "washington dc" => "DC", "florida" => "FL",
    "georgia" => "GA", "hawaii" => "HI", "idaho" => "ID", "illinois" => "IL", "indiana" => "IN",
    "iowa" => "IA", "kansas" => "KS", "kentucky" => "KY", "louisiana" => "LA", "maine" => "ME",
    "maryland" => "MD", "massachusetts" => "MA", "michigan" => "MI", "minnesota" => "MN",
    "mississippi" => "MS", "missouri" => "MO", "montana" => "MT", "nebraska" => "NE",
    "nevada" => "NV", "new hampshire" => "NH", "new jersey" => "NJ", "new mexico" => "NM",
    "new york" => "NY", "north carolina" => "NC", "north dakota" => "ND", "ohio" => "OH",
    "oklahoma" => "OK", "oregon" => "OR", "pennsylvania" => "PA", "puerto rico" => "PR",
    "rhode island" => "RI", "south carolina" => "SC", "south dakota" => "SD",
    "tennessee" => "TN", "texas" => "TX", "utah" => "UT", "vermont" => "VT",
    "virginia" => "VA", "washington" => "WA", "west virginia" => "WV", "wisconsin" => "WI",
    "wyoming" => "WY"
  }.freeze
  STATE_CODES = STATE_NAMES.values.uniq.freeze

  # What a search resolved to. `label` is what the results page calls it ("Dayton, OH").
  Point = Data.define(:label, :latitude, :longitude)
  # A city name that exists in more than one state, searched without one.
  Ambiguous = Data.define(:city, :states)

  FILE = Rails.root.join("lib/assets/census_locations.csv.gz")

  validates :kind, inclusion: {in: KINDS}

  # Replaces every row with the committed file. Run by the migration that creates the table, by
  # `bin/rails db:load_census_locations`, and by the seeds; never at request time.
  def self.load_from_file!(file = FILE)
    rows = Zlib::GzipReader.open(file) { |gz| CSV.parse(gz.read, headers: true).map(&:to_h) }
    transaction do
      delete_all
      rows.each_slice(5_000) { |slice| insert_all(slice) }
    end
    rows.size
  end
  validates :name, :name_key, :latitude, :longitude, presence: true

  # One spelling for every way a place name is written: case, punctuation, spacing and "Saint"
  # against "St." all collapse, so "St. Petersburg", "Saint Petersburg" and "ST PETERSBURG" agree.
  def self.key_for(name)
    name.to_s.downcase.gsub(/\bsaint\b/, "st").gsub(/[^a-z0-9]/, "")
  end

  # "OH", "oh" or "Ohio" to "OH"; nil for anything else.
  def self.state_code(value)
    value = value.to_s.strip
    return value.upcase if STATE_CODES.include?(value.upcase)
    STATE_NAMES[value.downcase.squeeze(" ").delete(".")]
  end

  # What a visitor typed, to a Point, an Ambiguous, or nil.
  #
  # Accepts a ZIP ("45402", "45402-1234"), "City, ST", "City ST", "City, State" and "City State",
  # and a city alone when only one state has a place by that name.
  def self.locate(query)
    query = query.to_s.strip.squeeze(" ")
    return if query.blank?

    if (zip = query[/\A(\d{5})(?:-\d{4})?\z/, 1])
      row = find_by(kind: "zip", name_key: zip)
      return row && Point.new(label: zip, latitude: row.latitude, longitude: row.longitude)
    end

    city, state = split_city_and_state(query)
    return if city.blank?
    return find_city(city, state) if state
    # "Dayton, Ohioo": a state was given and is not one. Not found, rather than "which Dayton?".
    return if query.include?(",")

    rows = where(kind: "place", name_key: key_for(city)).to_a
    return if rows.empty?
    return point_for(rows.first) if rows.map(&:state).uniq.one?
    Ambiguous.new(city: rows.first.name, states: rows.map(&:state).uniq.sort)
  end

  # A city in a known state, to a Point or nil. Places first, then townships and New England
  # towns. "Lawrence Township" is in the Census files as "Lawrence", so a trailing
  # township/twp/town is tried without it as well.
  def self.find_city(city, state)
    keys = [key_for(city), key_for(city.sub(/\s+(township|twp\.?|town)\z/i, ""))].uniq
    %w[place county_subdivision].each do |kind|
      keys.each do |key|
        row = find_by(kind: kind, state: state, name_key: key)
        return point_for(row) if row
      end
    end
    nil
  end

  def self.split_city_and_state(query)
    if query.include?(",")
      city, _, state = query.rpartition(",")
      return [city.strip, state_code(state)]
    end

    words = query.split(" ")
    # The longest trailing run of words that names a state: "New York" before "York".
    [3, 2, 1].each do |n|
      next if words.size <= n
      if (code = state_code(words.last(n).join(" ")))
        return [words.first(words.size - n).join(" "), code]
      end
    end
    [query, nil]
  end

  def self.point_for(row)
    Point.new(label: "#{row.name}, #{row.state}", latitude: row.latitude, longitude: row.longitude)
  end

  private_class_method :split_city_and_state, :point_for
end
