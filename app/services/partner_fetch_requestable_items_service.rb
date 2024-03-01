class PartnerFetchRequestableItemsService
  def initialize(partner_id:)
    @partner_id = partner_id
  end

  def call
    requestable_items = if partner.partner_group.blank?
      organization.items.active.visible
    else
      partner.requestable_items.active.visible
    end

    requestable_items.map { |item| [item.name, item.id] }.sort
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
