class AddNotesAndQuotaForPartners < ActiveRecord::Migration[6.0]
  def change
    add_column :partners, :notes, :text
    add_column :partners, :quota, :integer
  end
end
