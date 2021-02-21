class AddAuthorizedFamilyMemberIdToChildItemRequests < ActiveRecord::Migration[5.2]
  def change
    add_column :child_item_requests, :authorized_family_member_id, :integer
  end
end
