class RequestsConfirmationMailer < ApplicationMailer
  def confirmation_email(request)
    @organization = request.organization
    @partner = request.partner
    @request_items = fetch_items(request)
    requestee_email = request.user_email

    mail(to: requestee_email, cc: @partner.email, subject: "#{@organization.name} - Requests Confirmation")
  end

  private

  def fetch_items(request)
    items_sorted = request.request_items.sort_by { |k| k['item_id'] }
    item_ids = items_sorted&.map { |item| item['item_id'] }
    items_names = Item.where(id: item_ids).order(:id).pluck(:name)
    names_hash = items_names.map { |name| { 'name' => name } }

    items_sorted.zip(names_hash).map { |items, names| items.merge(names) }
  end
end
