class ChangeTextProfileColumnName < ActiveRecord::Migration[7.0]
  def change
    safety_assured {
      rename_column :partner_profiles, :max_serve, :client_capacity
      rename_column :partner_profiles, :program_contact_name, :primary_contact_name
      rename_column :partner_profiles, :program_contact_phone, :primary_contact_phone
      rename_column :partner_profiles, :program_contact_mobile, :primary_contact_mobile
      rename_column :partner_profiles, :program_contact_email, :primary_contact_email
    }
  end
end
