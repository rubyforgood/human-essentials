class KitCreateService
  include ServiceObjectErrorsMixin

  KIT_BASE_ITEM_ATTRS = {
    name: 'Kit',
    category: 'kit',
    partner_key: 'kit'
  }

  attr_reader :kit

  def self.FindOrCreateKitBaseItem!
    BaseItem.find_or_create_by!(KIT_BASE_ITEM_ATTRS)
  end

  def initialize(organization_id:, kit_params:)
    @organization_id = organization_id
    @kit_params = kit_params
  end

  def call
    return self unless valid?

    organization.transaction do
      # Create the Kit record
      @kit = Kit.new(kit_params_with_organization)
      @kit.save!

      # Find or create the BaseItem for all items housing kits
      item_housing_a_kit_base_item = KitCreateService.FindOrCreateKitBaseItem!

      # Create the item
      item_creation = ItemCreateService.new(
        organization_id: organization.id,
        item_params: {
          name: kit.name,
          partner_key: item_housing_a_kit_base_item.partner_key,
          kit_id: kit.id
        }
      )

      item_creation_result = item_creation.call
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

  def kit_params_with_organization
    kit_params.merge({
                       organization_id: organization.id
                     })
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

    kit = Kit.new(kit_params_with_organization)
    kit.valid?

    @kit_validation_errors = kit.errors
  end
end
