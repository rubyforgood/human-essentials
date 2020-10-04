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
      begin
        # Create the Kit record

        @kit = Kit.new(kit_params_with_organization)
        @kit.save!

        # Must create a BaseItem as well..
        #
        # Could we get away with just using an Item?
        base_item = BaseItem.new({
          name: "[KIT] #{kit.name}",
          partner_key: unique_partner_key(kit.name)
        })
        base_item.save!

        # Create the Item.
        item_creation = ItemCreateService.new(
          organization_id: organization.id,
          item_params: {
            name: kit.name,
            partner_key: unique_partner_key(kit.name),
            kit_id: kit.id
          }
        )

        result = item_creation.call
      rescue => e
        errors.add(:base, e.message)
        raise ActiveRecord::Rollback
      end
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

  def unique_partner_key(name)
    "organizations/#{organization.id}/kit_#{name.underscore.gsub(/\s+/,'_')}"
  end

  def valid?
    if organization.blank?
      errors.add(:organization_id, 'does not match any Organization')
    elsif kit_validation_errors.present?
      # Inject errors into self instance
      kit_validation_errors.each do |attr, kit_errors|
        [*kit_errors].each do |e|
          errors.add(attr.to_sym, e)
        end
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
    "kit_#{name.underscore.gsub(/\s+/,'_')}"
  end

end

