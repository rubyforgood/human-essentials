class RequestsConfirmationMailer < ApplicationMailer
  def confirmation_email(request)
    @organization = request.organization
    @partner = request.partner
    @request_items = fetch_items(request)
    requester = request.requester
    @requester_user_name = requester.is_a?(User) ? requester.name : nil # Requester can be the partner, if no user is specified
    # If the organization has opted in to receiving an email when a request is made, CC them
    cc = [@partner.email]
    if @organization.receive_email_on_requests
      cc.push(@organization.email)
    end
    cc.flatten!
    cc.compact!
    cc.uniq!
    mail(to: requester.email, cc: cc, subject: "#{@organization.name} - Requests Confirmation")
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
    grouped = request.request_items.group_by { |i| [i['item_id'], i['request_unit']] }
    # convert hash into an array of items with combined quantities
    grouped.map do |id_unit, items|
      { 'item_id' => id_unit.first, 'quantity' => items.map { |i| i['quantity'] }.sum, "unit" => id_unit.last }
    end
  end
end
