# A ZIP code is not a number.
#
# `partner_profiles.program_zip_code` was an integer while `zip_code` beside it was a string, so the
# same value was stored two different ways on one row -- and the integer one loses data:
#
#   * **Leading zeros are gone.** Every ZIP in MA, RI, NH, ME, VT, CT, NJ and Puerto Rico begins
#     with a 0, and `"04194".to_i` is `4194`. Measured in the seed database: 2 of 5 stored values
#     are under 10000, which is what a lost leading zero looks like.
#   * **ZIP+4 will not go in at all.** `"39428-1234"` casts to `39428`. 4 of the 7 profiles that
#     have the *string* zip_code use ZIP+4, so this is the normal case, not an edge one.
#   * And simple_form renders an integer column as `type="number"`, which is why that field had a
#     spinner on it.
#
# The backfill pads to five digits, which is the exact inverse of the cast that damaged them: an
# integer under 10000 in this column can only have arrived from a 5-character string beginning with
# a zero. Values already five digits are unchanged.
class MakeProgramZipCodeAString < ActiveRecord::Migration[8.1]
  # `safety_assured`, and why. strong_migrations blocks a type change because it rewrites the table
  # under a lock, and its advised alternative is a six-step add/backfill/swap across several
  # deploys. That is the right answer for a large table and the wrong one here: `partner_profiles`
  # holds **exactly one row per partner**, so this is a rewrite of a few thousand rows at the very
  # most, measured in milliseconds. The precedent is `20210409193928` and `20210425013259`.
  def up
    safety_assured do
      change_column :partner_profiles, :program_zip_code, :string
      # An UPDATE strong_migrations cannot see inside, on the same few thousand rows.
      execute <<~SQL
        UPDATE partner_profiles
           SET program_zip_code = LPAD(program_zip_code, 5, '0')
         WHERE program_zip_code IS NOT NULL
           AND program_zip_code <> ''
           AND LENGTH(program_zip_code) < 5
      SQL
    end
  end

  # Reversible, and lossy in the direction that made this necessary: going back to an integer drops
  # the leading zeros and any ZIP+4 again. Named here rather than left for someone to discover.
  def down
    safety_assured do
      execute <<~SQL
        UPDATE partner_profiles
           SET program_zip_code = SPLIT_PART(program_zip_code, '-', 1)
         WHERE program_zip_code LIKE '%-%'
      SQL
      change_column :partner_profiles, :program_zip_code, :integer,
        using: "NULLIF(program_zip_code, '')::integer"
    end
  end
end
