class ItemCreateService

  def initialize(organization_id:, item_params:)
    @organization_id = organization_id
    @item_params = item_params
  end

  def call
    organization.transaction do
      new_item = organization.items.new(item_params)
      new_item.save!

      organization.storage_locations.each do |sl|
        InventoryItem.create!({
          storage_location_id: sl.id,
          item_id: new_item.id,
          quantity: 0
        })
      end
    end

    OpenStruct.new(success?: true)
  rescue StandardError => e
    OpenStruct.new(success?: false, error: e)
  end

  private

  attr_reader :organization_id, :item_params

  def organization
    @organization ||= Organization.find(organization_id)
  end

end
