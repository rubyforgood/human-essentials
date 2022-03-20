class KitCreateService
  include ServiceObjectErrorsMixin

  attr_reader :kit

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

      # Create a BaseItem that houses each
      # kit item created.
      kit_base_item = fetch_or_create_kit_base_item

      # Create the Item.
      item_creation = ItemCreateService.new(
        organization_id: organization.id,
        item_params: {
          name: kit.name,
          partner_key: kit_base_item.partner_key,
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

  def fetch_or_create_kit_base_item
    BaseItem.find_or_create_by!({
                                  name: 'Kit',
                                  category: 'kit',
                                  partner_key: 'kit'
                                })
  end

  def partner_key_for_kits
    'kit'
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

  def associated_item_params
    {
      kit: kit.name
    }
  end

  def partner_key_for(name)
    "kit_#{name.underscore.gsub(/\s+/, '_')}"
  end
end

