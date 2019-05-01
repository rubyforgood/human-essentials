class BarcodeItem < ApplicationRecord
end

class RenameCanonicalItemToBaseItemInBarcodeable < ActiveRecord::Migration[5.2]
  def up
    BarcodeItem.where(barcodeable_type: "CanonicalItem").update_all(barcodeable_type: "BaseItem")
  end

  def down
    BarcodeItem.where(barcodeable_type: "BaseItem").update_all(barcodeable_type: "CanonicalItem")
  end
end
