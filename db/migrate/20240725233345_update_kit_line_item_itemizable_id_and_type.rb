class UpdateKitLineItemItemizableIdAndType < ActiveRecord::Migration[7.1]
  # #3707 all kits' line_items itemizable now point to kit's item instead of kit
  def change
    line_items = LineItem.where(itemizable_type: "Kit")

    line_items.each do |line_item|
      kit_item = line_item.itemizable.item

      line_item.itemizable = kit_item

      line_item.save!
    end
  end
end
