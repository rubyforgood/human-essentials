# Drops the freeform `address` column from the four models that now store four parts.
#
# The second half of `20260901185000`, which added `street`, `city`, `state` and `zipcode` and
# backfilled them. Since that migration the column has been in `ignored_columns` on all four models,
# so nothing has read or written it: `#address` composes the four parts and `#address=` parses into
# them. See "Address fields" in design.md.
#
# **This was meant to be a later release than the one that set `ignored_columns`.** That gap is what
# lets a rolling deploy finish safely -- an old process still running the previous code reads a
# column that is still there. Run in the same release, that protection is not there, and the window
# is the length of the deploy. Recorded because the sequence is the whole reason the two migrations
# are separate files, and someone reading them later should know it was collapsed deliberately
# rather than by accident.
#
# One query had to move first: `db/seeds.rb` looked donation sites up with
# `find_or_create_by!(address:)`. A query needs a real column -- `ignored_columns` hides an
# attribute but the SQL still resolved while the column existed -- so it keyed on the address right
# up until this migration would have broken it. It keys on name and organization now, which is the
# model's own uniqueness rule.
class RemoveAddressFromProviders < ActiveRecord::Migration[8.1]
  TABLES = %i[vendors donation_sites product_drive_participants storage_locations].freeze

  def up
    # `safety_assured` because the condition strong_migrations asks for is met: the column was added
    # to `ignored_columns` in a prior commit, so no running code refers to it. What it cannot check
    # is whether that commit has actually been deployed yet -- see the note above.
    safety_assured do
      TABLES.each { |table| remove_column table, :address }
    end
  end

  # Reversible, and it puts the data back rather than just the column: the four parts compose into
  # the same string the column held, which is exactly what `20260901185000` verified for all 18 rows
  # when it split them.
  def down
    TABLES.each do |table|
      add_column table, :address, :string
      execute(<<~SQL)
        UPDATE #{table}
           SET address = CONCAT_WS(', ', NULLIF(street, ''), NULLIF(city, ''),
                 NULLIF(TRIM(CONCAT_WS(' ', NULLIF(state, ''), NULLIF(zipcode, ''))), ''))
         WHERE COALESCE(street, city, state, zipcode) IS NOT NULL
      SQL
    end
  end
end
