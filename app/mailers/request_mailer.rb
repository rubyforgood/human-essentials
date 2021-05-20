class RequestMailer < ApplicationMailer
  def request_cancel_partner_notification(request_id:)
    @request ||= Request.find(request_id)
    @organization ||= @request.organization
    @partner = @request.partner

    # Generate the request_items in a formatted way so
    # I can render Item names
    item_ids = @request.request_items.map { |r| r['item_id'] }
    item_lookup_hash = Item.where(id: item_ids).index_by(&:id)
    @formatted_requested_items = @request.request_items.map do |rt|
      {
        name: item_lookup_hash[rt['item_id']]&.name || 'Unknown Item',
        quantity: rt['quantity']
      }
    end
    @formatted_requested_items.sort_by! { |rt| rt[:name] }

    mail(
      to: @partner.email,
      subject: "Your essentials request (##{@request.id}) has been canceled."
    )
  end
end
