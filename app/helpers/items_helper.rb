module ItemsHelper
=begin
# TODO: Migrate the controller helpers over to here
  def new_storage_collection
    @storages.each do |storage|
      @row_collection[storage.id] = ''
    end
    @row_collection[:item_quantity] = 0
    @row_collection[:item_id] = nil
  end

  def update_storage_collection(item)
      @row_collection[item.storage_id] = item.quantity
      @row_collection[:item_id] = item.id
      @row_collection[:item_name] = item.name
      @row_collection[:item_category] = item.category
      @row_collection[:item_barcode_count] = item.barcode_count
      @row_collection[:item_quantity] += item.quantity.nil? ? 0 : item.quantity
  end
=end
end
