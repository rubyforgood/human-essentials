class PartnerRequestableItemsService
  def initialize(organization_id:, partner_id:)
    @organization_id = organization_id
    @partner_id = partner_id
  end

  def call
    return organization.valid_items if partner.partner_groups.empty?

    partner.requestable_items.active.visible.map do |item|
      {
        id: item.id,
        partner_key: item.partner_key,
        name: item.name
      }
    end
  end

  private

  attr_reader :organization_id, :partner_id

  def organization
    @organization ||= Organization.find(organization_id)
  end

  def partner
    @partner ||= Partner.find(partner_id)
  end
end
