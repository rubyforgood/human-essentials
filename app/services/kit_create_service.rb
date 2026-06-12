class KitCreateService
  include ServiceObjectErrorsMixin

  KIT_BASE_ITEM_ATTRS = {
    name: 'Kit',
    category: 'kit',
    partner_key: 'kit'
  }

  attr_reader :kit

  def self.find_or_create_kit_base_item!
    BaseItem.find_or_create_by!(KIT_BASE_ITEM_ATTRS)
  end

  def initialize(organization_id:, kit_params:)
    @organization_id = organization_id
    @kit_params = kit_params
  end

  def call
    return self unless valid?

    organization.transaction do
      if kit_params[:line_items_attributes].blank?
        @kit = build_kit_item
        @kit.errors.add(:base, 'At least one item is required')
        raise ActiveRecord::RecordInvalid.new(@kit)
      end

      # A kit is just a KitItem - an Item that contains other items as line items.
      item_creation = ItemCreateService.new(
        organization_id: organization.id,
        item_params: kit_item_params
      )

      item_creation_result = item_creation.call
      unless item_creation_result.success?
        raise item_creation_result.error
      end

      @kit = item_creation_result.value
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

  # All kit items share the same "Kit" base item / partner_key.
  def kit_item_params
    kit_params.merge(
      type: 'KitItem',
      partner_key: KitCreateService.find_or_create_kit_base_item!.partner_key
    )
  end

  def build_kit_item
    organization.kit_items.new(kit_params.except(:line_items_attributes))
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

    # Exclude line_items_attributes; the line item validity is checked when the item is saved.
    kit_item = build_kit_item
    kit_item.valid?

    @kit_validation_errors = kit_item.errors
  end
end
