class AddPartnerFormFieldsToOrganization < ActiveRecord::Migration[6.0]
  def change
    add_column :organizations, :partner_form_fields, :text, array: true, default: []
  end
end
