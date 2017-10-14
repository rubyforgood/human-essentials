class ChangeOrganizationIdToNullableForBarcodeItem < ActiveRecord::Migration[5.1]
  def change
    change_column_null :barcode_items, :organization_id, true
  end
end
