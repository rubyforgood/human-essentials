class RenameExecutiveDirectorToContactsInPartnerFormFields < ActiveRecord::Migration[8.0]
  class Organization < ApplicationRecord
    self.table_name = "organizations"
  end

  def up
    organizations_to_update = Organization.where.not(partner_form_fields: [])
    organizations_to_update.each do |org|
      if org.partner_form_fields.include?("executive_director")
        org.partner_form_fields =
          org.partner_form_fields.map { |f| f == "executive_director" ? "contacts" : f }
        org.save!
      end
    end

    still_has_old_field = Organization.where("? = ANY (partner_form_fields)", "executive_director").exists?
    raise "Migration failed: some organizations still have 'executive_director' in partner_form_fields" if still_has_old_field
  end

  def down
    organizations_to_update = Organization.where.not(partner_form_fields: [])
    organizations_to_update.each do |org|
      if org.partner_form_fields.include?("contacts")
        org.partner_form_fields =
          org.partner_form_fields.map { |f| f == "contacts" ? "executive_director" : f }
        org.save!
      end
    end

    still_has_contacts_field = Organization.where("? = ANY (partner_form_fields)", "contacts").exists?
    raise "Rollback failed: some organizations still have 'contacts' in partner_form_fields" if still_has_contacts_field
  end
end
