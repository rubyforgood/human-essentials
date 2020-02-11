class AddInvitationTextToOrganization < ActiveRecord::Migration[5.2]
  def change
    add_column :organizations, :invitation_text, :text
  end
end
