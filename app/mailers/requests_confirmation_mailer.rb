class RequestsConfirmationMailer < ApplicationMailer
  def confirmation_email(request)
    @organization = request.organization
    @partner = request.partner
    @request_items = fetch_items(request)

    mail(to: @partner.email, subject: "#{@organization.name} - Requests Confirmation")
  end

  private

  def fetch_items(request)
    combined = combined_items(request)
    item_ids = combined&.map { |item| item['item_id'] }
    items_names = Item.where(id: item_ids).order(:id).pluck(:name)
    names_hash = items_names.map { |name| { 'name' => name } }
    combined.zip(names_hash).map { |items, names| items.merge(names) }
  end

  def combined_items(request)
    return [] if request.request_items.size == 0
    sorted = request.request_items.sort_by { |k| k['item_id'] }
    combined = [sorted[0]]
    sorted[1..].each do |request_item|
      if request_item["item_id"] == combined.last["item_id"]
        combined.last["quantity"] = combined.last["quantity"] + request_item["quantity"]
      else
        combined.push request_item
      end
    end
    combined
  end
end
