class AddOneStepPartnerInviteToOrganization < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      add_column :organizations, :one_step_partner_invite, :boolean, default: false, null: false
    end
  end
end
