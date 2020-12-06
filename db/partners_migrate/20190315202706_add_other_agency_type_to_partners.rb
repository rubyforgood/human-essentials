class AddOtherAgencyTypeToPartners < ActiveRecord::Migration[5.2]
  def change
    add_column :partners, :other_agency_type, :string
  end
end
