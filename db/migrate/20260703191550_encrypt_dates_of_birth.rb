class EncryptDatesOfBirth < ActiveRecord::Migration[8.0]
  def up
    # date -> string: encrypted values are string blobs and won't fit a date column. `string` (not
    # `text`) matches the other encrypted PII columns; on Postgres an unbounded varchar stores the
    # same as text and holds the ciphertext fine.
    #
    # `using` pins the serialization format. Without it Postgres falls back to the date output
    # function, which follows the server's DateStyle setting: under `SQL, MDY` the same date is
    # written as "03/04/1990", which Ruby then reads back as April 3rd. This rewrite is in place
    # and irreversible, so the format cannot be left to a server setting.
    safety_assured do
      change_column :children, :date_of_birth, :string, using: "to_char(date_of_birth, 'YYYY-MM-DD')"
      change_column :authorized_family_members, :date_of_birth, :string, using: "to_char(date_of_birth, 'YYYY-MM-DD')"
    end
  end

  def down
    safety_assured do
      change_column :children, :date_of_birth, :date, using: "date_of_birth::date"
      change_column :authorized_family_members, :date_of_birth, :date, using: "date_of_birth::date"
    end
  end
end
