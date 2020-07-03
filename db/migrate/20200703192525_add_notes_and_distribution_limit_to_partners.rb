class AddNotesAndDistributionLimitToPartners < ActiveRecord::Migration[6.0]
  def change
    add_column :partners, :note, :text
    add_column :partners, :distribution_limit, :integer
  end
end
