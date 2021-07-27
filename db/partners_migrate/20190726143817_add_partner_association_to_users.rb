class AddPartnerAssociationToUsers < ActiveRecord::Migration[5.2]
  def change
    add_reference :users, :partner, foreign_key: true
  end
end
