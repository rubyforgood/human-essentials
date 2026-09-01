# Four address columns for the four models that kept one freeform string.
#
# `Vendor`, `DonationSite`, `ProductDriveParticipant` and `StorageLocation` each stored `address`,
# where `Organization` has always stored `street`, `city`, `state` and `zipcode`. Reported on the
# vendor form; see "Address fields" in design.md and the 2026-09-01 entry in docs/design-decisions.md
# for why the CSV import templates deliberately did *not* change with it.
#
# **The old `address` column is not dropped here, and not in this release.** The models add it to
# `ignored_columns` in the same commit, so nothing reads or writes it from now on -- and a *later*
# migration removes it. That gap is the point: between the two deploys an old process still running
# the previous code can read `address` without hitting a column that has vanished underneath it.
# Shipping the drop in the same release would collapse the gap and make the sequence pointless.
# These four tables are read by the geocoder, four PDFs and three CSV exports, which is what makes
# the extra step worth taking. The follow-up is named in docs/migration-map.md.
#
# **The parser is a copy of `StructuredAddress.parse`, on purpose.** A migration has to keep working
# years from now with no application code around it -- the house pattern here, set by
# `20260612120000`, is raw SQL and no model constants. Copying it costs nothing because this runs
# once, and the two were verified to produce identical output for every row in the database before
# this was committed.
class AddStructuredAddressToProviders < ActiveRecord::Migration[8.1]
  TABLES = %i[vendors donation_sites product_drive_participants storage_locations].freeze

  STATE_CODES = %w[
    AK AL AR AZ CA CO CT DC DE FL GA HI IA ID IL IN KS KY LA MA MD ME MI MN MO MS MT NC ND NE NH
    NJ NM NV NY OH OK OR PA RI SC SD TN TX UT VA VT WA WI WV WY
  ].freeze

  ZIP = /\s*(\d{5}(?:-\d{4})?)\z/

  def up
    TABLES.each do |table|
      add_column table, :street, :string
      add_column table, :city, :string
      add_column table, :state, :string
      add_column table, :zipcode, :string
    end

    # The backfill: one UPDATE per row, which strong_migrations cannot see inside. Safe because the
    # columns being written were created by this same migration a moment ago, so nothing else in the
    # system reads them yet and no row is locked for longer than its own update.
    safety_assured { backfill }
  end

  def backfill
    TABLES.each do |table|
      rows = connection.select_all(
        "SELECT id, address FROM #{table} WHERE address IS NOT NULL AND address <> ''"
      )
      rows.each do |row|
        parts = parse(row["address"])
        execute(<<~SQL)
          UPDATE #{table}
             SET street = #{connection.quote(parts[:street])},
                 city = #{connection.quote(parts[:city])},
                 state = #{connection.quote(parts[:state])},
                 zipcode = #{connection.quote(parts[:zipcode])}
           WHERE id = #{row["id"].to_i}
        SQL
      end
      say "backfilled #{rows.count} #{table}"
    end
  end

  # Composes the four parts back into the column they came from, so the data is never only in the
  # columns this is about to remove.
  def down
    TABLES.each do |table|
      execute(<<~SQL)
        UPDATE #{table}
           SET address = CONCAT_WS(', ', NULLIF(street, ''), NULLIF(city, ''),
                 NULLIF(TRIM(CONCAT_WS(' ', NULLIF(state, ''), NULLIF(zipcode, ''))), ''))
         WHERE COALESCE(street, city, state, zipcode) IS NOT NULL
      SQL
      remove_column table, :street
      remove_column table, :city
      remove_column table, :state
      remove_column table, :zipcode
    end
  end

  private

  # Reads from the end inwards, because the end is the part with a shape: a ZIP is unmistakable and
  # a state is one of 51 known codes. Whatever is left over stays in `street` rather than being
  # guessed at, so no text is ever discarded.
  def parse(text)
    rest = text.to_s.strip.gsub(/\s+/, " ")
    return {street: "", city: "", state: "", zipcode: ""} if rest.empty?

    zipcode = rest.slice!(ZIP) ? Regexp.last_match(1) : ""
    rest = rest.sub(/[,\s]+\z/, "")

    state = ""
    if (found = rest[/(?:\A|[,\s])([A-Za-z]{2})\z/, 1]) && STATE_CODES.include?(found.upcase)
      state = found.upcase
      rest = rest[0...-found.length].sub(/[,\s]+\z/, "")
    end

    street, city = rest.include?(",") ? rest.rpartition(",").values_at(0, 2) : [rest, ""]
    {street: street.strip, city: city.strip, state: state, zipcode: zipcode}
  end
end
