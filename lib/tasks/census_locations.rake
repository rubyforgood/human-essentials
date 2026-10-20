require "csv"
require "zlib"

# The bank finder's location data. See CensusLocation and ADR 0014.

namespace :census_locations do
  # Rebuilds lib/assets/census_locations.csv.gz from the Census Bureau's Gazetteer files. Only
  # needed when Census publishes a new year; the result is committed, so setup never downloads.
  #
  #   Download and unzip, from https://www.census.gov/geographies/reference-files/time-series/geo/gazetteer-files.html:
  #     2024_Gaz_place_national.txt, 2024_Gaz_cousubs_national.txt, 2024_Gaz_zcta_national.txt
  #   bin/rails "census_locations:build[/path/to/unzipped/files]"
  desc "Build lib/assets/census_locations.csv.gz from Census Gazetteer files in DIR"
  task :build, [:dir] => :environment do |_, args|
    dir = Pathname.new(args.fetch(:dir))
    read = lambda do |pattern|
      file = Dir[dir.join(pattern)].max or abort "No #{pattern} in #{dir}"
      CSV.foreach(file, col_sep: "\t", headers: true, encoding: "bom|utf-8", liberal_parsing: true)
        .map { |row| row.to_h.transform_keys(&:strip).transform_values { |v| v&.strip } }
    end

    # The Census names carry their legal type: "Dayton city", "Montclair township", "Hyannis CDP".
    # A consolidated city is named for both halves -- "Nashville-Davidson metropolitan government
    # (balance)" -- so it also gets a key for the city half, which is what anyone types.
    consolidated = /\s+(?:metropolitan government|consolidated government|unified government|urban county|metro government)\z/i
    legal_type = /\s+(?:city and borough|municipality|city|town|township|charter township|village|borough|plantation|CDP|zona urbana|comunidad|UT|gore|grant|location|purchase)\z/i
    names = lambda do |raw|
      name = raw.sub(/\s+\((?:balance|pt\.)\)\z/i, "")
      if name.match?(consolidated)
        name = name.sub(consolidated, "")
        # The city half first: it is what the results page calls it ("Nashville, TN").
        [name.split(%r{[-/]}).first.sub(/\s+county\z/i, ""), name]
      else
        [name.sub(legal_type, "").sub(/\AUrban\s+/, "")]
      end
    end

    rows = {}
    {"place" => "*_Gaz_place_national.txt", "county_subdivision" => "*_Gaz_cousubs_national.txt"}.each do |kind, pattern|
      read.call(pattern).each do |r|
        next if r["NAME"].match?(/\A(?:County subdivisions not defined|Remainder of)/i)
        names.call(r["NAME"]).uniq.each do |name|
          key = [kind, r["USPS"], CensusLocation.key_for(name)]
          # Two places with one name in one state: keep the larger. A CDP sharing a city's name
          # is always the smaller.
          next if rows[key] && rows[key][:land] >= r["ALAND"].to_i
          rows[key] = {kind:, state: r["USPS"], name: names.call(r["NAME"]).first, name_key: key.last,
                       latitude: r["INTPTLAT"], longitude: r["INTPTLONG"], land: r["ALAND"].to_i}
        end
      end
    end
    read.call("*_Gaz_zcta_national.txt").each do |r|
      rows[["zip", nil, r["GEOID"]]] = {kind: "zip", state: nil, name: r["GEOID"], name_key: r["GEOID"],
                                        latitude: r["INTPTLAT"], longitude: r["INTPTLONG"]}
    end

    Zlib::GzipWriter.open(CensusLocation::FILE) do |gz|
      gz.write(%w[kind state name name_key latitude longitude].to_csv)
      rows.each_value { |r| gz.write(r.values_at(:kind, :state, :name, :name_key, :latitude, :longitude).to_csv) }
    end
    counts = rows.values.group_by { |r| r[:kind] }.transform_values(&:size)
    puts "Wrote #{rows.size} locations (#{counts.map { |k, v| "#{v} #{k}" }.join(", ")}) to #{CensusLocation::FILE.relative_path_from(Rails.root)}"
  end
end

namespace :db do
  desc "Load the bank finder's Census locations from lib/assets/census_locations.csv.gz"
  task load_census_locations: :environment do
    puts "Loaded #{CensusLocation.load_from_file!} Census locations."
  end
end
