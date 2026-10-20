# A handful of real Census rows, copied from lib/assets/census_locations.csv.gz, for the bank
# finder specs. Loading the whole file costs ~4s, and these cover every city the sample
# directories in db/seed_data/bank_listings name, plus the searches the specs make.
module CensusLocationsHelper
  ROWS = [
    ["place", "OH", "Dayton", "dayton", 39.784743, -84.199632],
    ["place", "OH", "Cincinnati", "cincinnati", 39.140183, -84.505829],
    ["place", "MA", "Worcester", "worcester", 42.269478, -71.807783],
    ["place", "MA", "Barnstable Town", "barnstabletown", 41.661478, -70.356951],
    ["place", "MT", "Helena", "helena", 46.596556, -112.021765],
    ["place", "OH", "Xenia", "xenia", 39.683133, -83.940808],
    ["place", "NC", "Winston-Salem", "winstonsalem", 36.102863, -80.260829],
    ["place", "MT", "Missoula", "missoula", 46.874359, -114.026136],
    ["place", "IL", "Springfield", "springfield", 39.791063, -89.644572],
    ["place", "MO", "Springfield", "springfield", 37.194157, -93.292642],
    ["place", "FL", "St. Petersburg", "stpetersburg", 27.762727, -82.644131],
    ["county_subdivision", "NJ", "Montclair", "montclair", 40.824998, -74.210856],
    ["county_subdivision", "NJ", "Lawrence", "lawrence", 39.334878, -75.184579],
    ["zip", nil, "45402", "45402", 39.760114, -84.207627],
    ["zip", nil, "59801", "59801", 46.854689, -114.010437]
  ].freeze

  def create_census_locations
    CensusLocation.insert_all(ROWS.map { |kind, state, name, name_key, latitude, longitude|
      {kind:, state:, name:, name_key:, latitude:, longitude:}
    })
  end

  def import_sample_bank_listings
    BankListingImportService.call(fetch: BankListingImportService::SAMPLE_FETCH)
  end
end

RSpec.configure { |config| config.include CensusLocationsHelper }
