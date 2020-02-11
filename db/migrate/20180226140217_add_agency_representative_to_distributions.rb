# Stakeholder request
class AddAgencyRepresentativeToDistributions < ActiveRecord::Migration[5.1]
  def change
    add_column :distributions, :agency_rep, :string
  end
end
