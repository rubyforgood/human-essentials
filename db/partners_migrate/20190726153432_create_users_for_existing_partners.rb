class CreateUsersForExistingPartners < ActiveRecord::Migration[5.2]
  def up
    execute(<<-SQL)
      INSERT INTO users (
        partner_id,
        email,
        encrypted_password,
        reset_password_token,
        reset_password_sent_at,
        remember_created_at,
        sign_in_count,
        current_sign_in_at,
        last_sign_in_at,
        current_sign_in_ip,
        last_sign_in_ip,
        created_at,
        updated_at,
        invitation_token,
        invitation_created_at,
        invitation_sent_at,
        invitation_accepted_at,
        invitation_limit,
        invited_by_type,
        invited_by_id,
        invitations_count
      ) (
        SELECT
          partners.id,
          partners.email,
          partners.encrypted_password,
          partners.reset_password_token,
          partners.reset_password_sent_at,
          partners.remember_created_at,
          partners.sign_in_count,
          partners.current_sign_in_at,
          partners.last_sign_in_at,
          partners.current_sign_in_ip::inet,
          partners.last_sign_in_ip::inet,
          partners.created_at,
          partners.updated_at,
          partners.invitation_token,
          partners.invitation_created_at,
          partners.invitation_sent_at,
          partners.invitation_accepted_at,
          partners.invitation_limit,
          partners.invited_by_type,
          partners.invited_by_id,
          partners.invitations_count
        FROM partners
      )
    SQL
  end

  def down
    execute(<<-SQL)
      DELETE FROM users
    SQL
  end
end
