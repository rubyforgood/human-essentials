class AddUserIdToAdjustments < ActiveRecord::Migration[5.2]
  def up
    add_reference :adjustments, :user, foreign_key: true

    Adjustment.all.each do |adjustment|
      adjustment.user_id = adjustment.organization.users.find_by(organization_admin: true).id
      adjustment.save
    end
  end

  def down
    remove_reference :adjustments, :user, foreign_key: true
  end
end
