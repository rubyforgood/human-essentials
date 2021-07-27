class AddSentToFamilyRequests < ActiveRecord::Migration[5.2]
  def change
    add_column :family_requests, :sent, :boolean
  end
end
