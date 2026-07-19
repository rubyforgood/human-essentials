class MoveLineItemsFromKitsToItems < ActiveRecord::Migration[8.0]
  def change
    Item.where.not(kit_id: nil).each do |item|
      LineItem.where(itemizable_type: 'Kit', itemizable_id: item.kit_id).
        update_all(itemizable_type: 'Item', itemizable_id: item.id, updated_at: Time.current)
    end
  end
end
