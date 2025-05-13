class MigrateOrganizationPartnerFormFieldsExecutiveDirectorToContacts < ActiveRecord::Migration[8.0]
  class Organization < ApplicationRecord
  end

  def up
    organizations_to_update = Organization.where.not(partner_form_fields: [])
    organizations_to_update.each do |org|
      if org.partner_form_fields.include?('executive_director')
        org.partner_form_fields.delete('executive_director')
        org.partner_form_fields << 'contacts'
        org.save!
      end
    end
  end

  def down
    organizations_to_update = Organization.where.not(partner_form_fields: [])
    organizations_to_update.each do |org|
      if org.partner_form_fields.include?('contacts')
        org.partner_form_fields.delete('contacts')
        org.partner_form_fields << 'executive_director'
        org.save!
      end
    end
  end

end
