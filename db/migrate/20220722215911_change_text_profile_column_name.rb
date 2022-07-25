class ChangeTextProfileColumnName < ActiveRecord::Migration[7.0]

  klass = Class.new(Partners::Base) do
     self.table_name = 'partner_profiles'
  end

  def change
    add_column :partner_profiles, :client_capacity, :string
    add_column :partner_profiles, :primary_contact_name, :string
    add_column :partner_profiles, :primary_contact_phone, :string
    add_column :partner_profiles, :primary_contact_mobile, :string
    add_column :partner_profiles,  :primary_contact_email, :string

    klass.all.find_each do |partner_profile|
      partner_profile.client_capacity = partner_profile.max_serve
      partner_profile.program_contact_name = partner_profile.primary_contact_name
      partner_profile.program_contact_phone = partner_profile.primary_contact_phone
      partner_profile.program_contact_mobile = partner_profile.primary_contact_mobile
      partner_profile.program_contact_email = partner_profile.primary_contact_email

      partner_profile.save(:validate => false)
    end 
  end
end
