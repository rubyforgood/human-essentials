class ItemsByStorageCollectionAndQuantityQuery
  attr_reader :organization, :filter_params, :items_by_storage_collection_and_quantity

  def initialize(organization:, filter_params:)
    @organization = organization
    @filter_params = filter_params
  end

  def call
    @items_by_storage_collection ||= ItemsByStorageCollectionQuery.new(organization: organization, filter_params: filter_params).call
    @items_by_storage_collection_and_quantity ||= Hash.new
    @items_by_storage_collection.each do |row|
      unless @items_by_storage_collection_and_quantity.key?(row.id)
        @items_by_storage_collection_and_quantity[row.id] = {
          item_name: row.name,
          item_category: row.category,
          item_value: row.value,
          item_barcode_count: row.barcode_count
        }
      end
      @items_by_storage_collection_and_quantity[row.id][row.storage_id] = row.quantity
      @items_by_storage_collection_and_quantity[row.id][:quantity] ||= 0
      @items_by_storage_collection_and_quantity[row.id][:quantity] += row.quantity || 0
    end

    @items_by_storage_collection_and_quantity
  end
end
