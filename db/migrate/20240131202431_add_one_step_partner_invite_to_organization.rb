class AddOneStepPartnerInviteToOrganization < ActiveRecord::Migration[7.0]
  def change
    add_column :organizations, :one_step_partner_invite, :boolean, null: false
    change_column_default :organizations, :one_step_partner_invite, false
  end
end
