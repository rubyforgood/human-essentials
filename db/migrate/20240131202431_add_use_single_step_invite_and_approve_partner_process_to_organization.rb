class AddUseSingleStepInviteAndApprovePartnerProcessToOrganization < ActiveRecord::Migration[7.0]
  def change
    add_column :organizations, :use_single_step_invite_and_approve_partner_process, :boolean
    change_column_default :organizations, :use_single_step_invite_and_approve_partner_process, false
  end
end
