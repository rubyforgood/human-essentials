class PartnerFetchRequestableItemsService
  def initialize(partner_id:)
    @partner_id = partner_id
  end

  def call
    return organization.items.active.visible.sort if partner.partner_group.blank?

    partner.requestable_items.active.visible
  end

  private

  attr_reader :partner_id

  def partner
    @partner ||= Partner.find(partner_id)
  end

  def organization
    @organization ||= partner.organization
  end
end
