# Fix to ensure that the object is available in the migration
class BarcodeItem < ApplicationRecord
end

# Calling them Canonical Items was a regrettable mistake
class RenameCanonicalItemToBaseItemInBarcodeable < ActiveRecord::Migration[5.2]
  def up
    BarcodeItem.where(barcodeable_type: "CanonicalItem").update_all(barcodeable_type: "BaseItem")
  end

  def down
    BarcodeItem.where(barcodeable_type: "BaseItem").update_all(barcodeable_type: "CanonicalItem")
  end
end
