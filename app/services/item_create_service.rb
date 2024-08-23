class ItemCreateService
  def initialize(organization_id:, item_params:, request_unit_ids: [])
    @organization_id = organization_id
    @request_unit_ids = request_unit_ids
    @item_params = item_params
  end

  def call
    new_item = organization.items.new(item_params)
    new_item.save!
      if Flipper.enabled?(:enable_packs)
        new_item.sync_request_units!(@request_unit_ids)
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
end
