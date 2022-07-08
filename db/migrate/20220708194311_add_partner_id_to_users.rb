class AddPartnerIdToUsers < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      add_reference :users, :partner
    end
  end
end
