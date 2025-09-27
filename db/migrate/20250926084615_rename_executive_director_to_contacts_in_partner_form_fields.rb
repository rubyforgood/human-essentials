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
  end
end
