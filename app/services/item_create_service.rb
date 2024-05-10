class ItemCreateService
  def initialize(organization_id:, item_params:)
    @organization_id = organization_id
    @item_params = item_params
  end

  def call
    new_item = organization.items.new(item_params)

    new_item.save!

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
