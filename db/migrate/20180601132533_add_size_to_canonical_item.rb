# "size" in this case refers to "2T", "5T", etc.
class AddSizeToCanonicalItem < ActiveRecord::Migration[5.2]
  def change
    add_column :canonical_items, :size, :string
  end
end
