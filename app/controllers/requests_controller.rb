# Provides Read-only access to Requests, which are created via an API. Requests are transformed into Distributions.
class RequestsController < ApplicationController
  def index
    setup_date_range_picker

    @requests = current_organization
                .ordered_requests
                .during(helpers.selected_range)
                .class_filter(filter_params)

    @paginated_requests = @requests.page(params[:page])
    @calculate_product_totals = total_items(@requests)
    @items = current_organization.items.alphabetized
    @partners = current_organization.partners.order(:name)
    @statuses = Request.statuses.transform_keys(&:humanize)
    @selected_request_item = filter_params[:by_request_item_id]
    @selected_partner = filter_params[:by_partner]
    @selected_status = filter_params[:by_status]
    respond_to { |format| format.html }
  end

  def show
    @request = Request.find(params[:id])
    @request_items = load_items
  end

  # Clicking the "New Distribution" button will set the the request to started
  # and will move the user to the new distribution page with a
  # pre-filled distribution containing all the requested items.
  def start
    request = Request.find(params[:id])
    request.status_started!
    flash[:notice] = "Request started"
    redirect_to new_distribution_path(request_id: request.id)
  end

  # TODO: kick off job to send email
  def destroy
    ActiveRecord::Base.transaction do
      Request.find(params[:id]).destroy!
    end
    flash[:notice] = "Request #{params[:id]} has been removed!"
    redirect_to requests_path
  end

  private

  def total_items(requests)
    request_items = []

    requests.pluck(:request_items).each do |items|
      items.map { |json| request_items << [Item.find(json['item_id']).name, json['quantity']] }
    end

    request_items.inject({}) do |item, (quantity, total)|
      item[quantity] ||= 0
      item[quantity] += total.to_i
      item
    end
  end

  def load_items
    return unless @request.request_items

    @request.request_items.map { |json| RequestItem.from_json(json, current_organization) }
  end

  def filter_params
    return {} unless params.key?(:filters)

    params.require(:filters).slice(:by_request_item_id, :by_partner, :by_status)
  end
end
