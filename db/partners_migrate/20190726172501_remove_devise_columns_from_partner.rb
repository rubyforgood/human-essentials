class RemoveDeviseColumnsFromPartner < ActiveRecord::Migration[5.2]
  def up
    devise_columns.each do |column|
      remove_column :partners, column
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  def devise_columns
    %i[email
       encrypted_password
       reset_password_token
       reset_password_sent_at
       remember_created_at
       sign_in_count
       current_sign_in_at
       last_sign_in_at
       current_sign_in_ip
       last_sign_in_ip
       invitation_token
       invitation_created_at
       invitation_sent_at
       invitation_accepted_at
       invitation_limit
       invited_by_type
       invited_by_id
       invitations_count]
  end
end
