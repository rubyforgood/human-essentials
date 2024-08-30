class KitCreateService
  include ServiceObjectErrorsMixin

  KIT_BASE_ITEM_ATTRS = {
    name: 'Kit',
    category: 'kit',
    partner_key: 'kit'
  }.freeze

  attr_reader :kit

  def self.FindOrCreateKitBaseItem!
    BaseItem.find_or_create_by!(KIT_BASE_ITEM_ATTRS)
  end

  def initialize(organization_id:, kit_params:)
    @organization_id = organization_id
    if kit_params.key?(:item)
      # Temporary hack to pretend line_items are directly under kit until the form view is changed when working on #3652
      kit_params[:line_items_attributes] = kit_params.delete(:item)[:line_items_attributes]
    end
    @item_housing_kit_params = kit_params
    # #3707 line items point to item_housing_kit, not the kit
    @kit_params_with_organization = kit_params.merge({organization_id: organization_id})
      .except(:line_items_attributes)
  end

  def call
    return self unless valid?

    organization.transaction do
      # Create the Kit record
      @kit = Kit.new(@kit_params_with_organization)
      @kit.save!

      # Find or create the BaseItem for all items housing kits
      item_housing_a_kit_base_item = KitCreateService.FindOrCreateKitBaseItem!

      # Create the item housing the kit along with associated line items (#3707)
      item_housing_kit_creation = ItemCreateService.new(
        organization_id: organization.id,
        item_params: @item_housing_kit_params.merge(
          kit_id: @kit.id,
          partner_key: item_housing_a_kit_base_item.partner_key,
          name: @kit.name
        )
      )

      item_creation_result = item_housing_kit_creation.call
      unless item_creation_result.success?
        raise item_creation_result.error
      end
    rescue StandardError => e
      errors.add(:base, e.message)
      raise ActiveRecord::Rollback
    end

    self
  end

  private

  attr_reader :organization_id, :kit_params
  def organization
    @organization ||= Organization.find_by(id: organization_id)
  end

  def valid?
    if organization.blank?
      errors.add(:organization_id, 'does not match any Organization')
    elsif kit_validation_errors.present?
      # Inject errors into self instance
      kit_validation_errors.each do |kit_validation_error|
        errors.add(kit_validation_error.attribute.to_sym, kit_validation_error.message)
      end
    end

    errors.empty?
  end

  def kit_validation_errors
    return @kit_validation_errors if @kit_validation_errors

    kit = Kit.new(@kit_params_with_organization)
    kit.valid?

    @kit_validation_errors = kit.errors
  end
end
