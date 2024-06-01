class RequestsConfirmationMailer < ApplicationMailer
  def confirmation_email(request)
    @organization = request.organization
    @partner = request.partner
    @request_items = fetch_items(request)
    requestee_email = request.user_email

    mail(to: requestee_email, cc: @partner.email, subject: "#{@organization.name} - Requests Confirmation")
  end

  private

  # TODO: remove the need to de-duplicate items in the request
  def fetch_items(request)
    combined = combined_items(request)
    item_ids = combined&.map { |item| item['item_id'] }
    db_items = Item.where(id: item_ids).select(:id, :name)
    combined.each { |i| i['name'] = db_items.find { |db_item| i["item_id"] == db_item.id }.name }
    combined.sort_by { |i| i['name'] }
  end

  def combined_items(request)
    return [] if request.request_items.size == 0
    # convert items into a hash of (id => list of items with that ID)
    grouped = request.request_items.group_by { |i| i['item_id'] }
    # convert hash into an array of items with combined quantities
    grouped.map do |id, items|
      { 'item_id' => id, 'quantity' => items.map { |i| i['quantity'] }.sum }
    end
  end
end
