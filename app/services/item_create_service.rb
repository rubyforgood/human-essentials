class ItemCreateService
  def initialize(organization_id:, item_params:)
    @organization_id = organization_id
    @request_unit_ids = item_params.fetch(:request_unit_ids, [])
    item_params.delete(:request_unit_ids)
    @item_params = item_params
  end

  def call
    new_item = organization.items.new(item_params)
    organization.transaction do
      new_item.save!
      create_request_units!(new_item)

      organization.storage_locations.each do |sl|
        InventoryItem.create!(
          storage_location_id: sl.id,
          item_id: new_item.id,
          quantity: 0
        )
      end
    end

    OpenStruct.new(success?: true, item: new_item)
  rescue StandardError => e
    OpenStruct.new(success?: false, error: e)
  end

  private

  attr_reader :organization_id, :item_params

  def organization
    @organization ||= Organization.find(organization_id)
  end

  def create_request_units!(item)
    return if @request_unit_ids.empty?
    organization.request_units.where(id: @request_unit_ids).pluck(:name).each do |name|
      item.request_units.create!(name:)
    end
  end
end
