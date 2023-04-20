class AddOneStepInviteToOrganizations < ActiveRecord::Migration[7.0]
  def up
    add_column :organizations, :enable_one_step_invite, :boolean
    change_column_default :organizations, :enable_one_step_invite, false
  end

  def down
    remove_column :organizations, :enable_one_step_invite
  end
end