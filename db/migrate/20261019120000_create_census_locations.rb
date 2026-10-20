# Where a bank finder search is measured from: Census places, county subdivisions and ZIP codes,
# loaded from lib/assets/census_locations.csv.gz. Read only, and the same for every organization,
# so it is not scoped to one. See ADR 0014.
class CreateCensusLocations < ActiveRecord::Migration[8.1]
  def change
    # No timestamps: every row is replaced at once from the file, so a row's own time says nothing.
    create_table :census_locations do |t| # rubocop:disable Rails/CreateTableWithTimestamps
      t.string :kind, null: false
      t.string :state
      t.string :name, null: false
      t.string :name_key, null: false
      t.float :latitude, null: false
      t.float :longitude, null: false
    end
    add_index :census_locations, [:kind, :state, :name_key]
    add_index :census_locations, [:kind, :name_key]

    # Reference data rather than records, and read only: loading it here means every
    # environment that migrates has it, with no deploy step to forget.
    reversible { |dir| dir.up { say_with_time("Loading Census locations") { load_census_locations } } }
  end

  private

  # A copy of the table's own model, so this migration keeps working if CensusLocation changes.
  class MigrationCensusLocation < ActiveRecord::Base
    self.table_name = "census_locations"
  end

  def load_census_locations
    require "csv"
    require "zlib"
    rows = Zlib::GzipReader.open(Rails.root.join("lib/assets/census_locations.csv.gz")) { |gz| CSV.parse(gz.read, headers: true).map(&:to_h) }
    rows.each_slice(5_000) { |slice| MigrationCensusLocation.insert_all(slice) }
    rows.size
  end
end
