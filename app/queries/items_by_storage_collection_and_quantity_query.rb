# Creates a query object for retrieving the items, grouped by storage location, also including quantities
# We're using query objects for some of these more complicated queries to get
# the raw SQL out of the models and encapsulate it.
class ItemsByStorageCollectionAndQuantityQuery
  attr_reader :organization, :filter_params, :items_by_storage_collection_and_quantity

  def initialize(organization:, filter_params:)
    @organization = organization
    @filter_params = filter_params
  end

  def call
    @items_by_storage_collection ||= ItemsByStorageCollectionQuery.new(organization: organization, filter_params: filter_params).call
    unless @filter_params[:include_inactive_items]
      @items_by_storage_collection = @items_by_storage_collection.active
    end
    @items_by_storage_collection_and_quantity ||= Hash.new
    @items_by_storage_collection.each do |row|
      unless @items_by_storage_collection_and_quantity.key?(row.id)
        @items_by_storage_collection_and_quantity[row.id] = {
          item_name: row.name,
          item_on_hand_minimum_quantity: row.on_hand_minimum_quantity,
          item_on_hand_recommended_quantity: row.on_hand_recommended_quantity,
          item_value: row.value_in_cents,
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
