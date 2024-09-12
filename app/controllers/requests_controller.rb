# Provides Read-only access to Requests, which are created via an API. Requests are transformed into Distributions.
class RequestsController < ApplicationController
  def index
    setup_date_range_picker

    @requests = current_organization
                .ordered_requests
                .undiscarded
                .during(helpers.selected_range)
                .class_filter(filter_params)
    @unfulfilled_requests = current_organization.requests.where(status: [:pending, :started])
    @paginated_requests = @requests.page(params[:page])
    @calculate_product_totals = RequestsTotalItemsService.new(requests: @requests).calculate
    @items = current_organization.items.alphabetized
    @partners = current_organization.partners.order(:name)
    @statuses = Request.statuses.transform_keys(&:humanize)
    @partner_users = User.where(id: @paginated_requests.pluck(:partner_user_id))
    @selected_request_item = filter_params[:by_request_item_id]
    @selected_partner = filter_params[:by_partner]
    @selected_status = filter_params[:by_status]

    respond_to do |format|
      format.html
      format.csv { send_data Exports::ExportRequestService.new(@requests).generate_csv, filename: "Requests-#{Time.zone.today}.csv" }
    end
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

  def print_unfulfilled
    requests = Request.includes(partner: [:profile]).where(status: [0, 1])

    respond_to do |format|
      format.any do
        pdf = PicklistsPdf.new(current_organization, requests)
        send_data pdf.compute_and_render,
          filename: format("Picklists_%s.pdf", Time.current.to_fs(:long)),
          type: "application/pdf",
          disposition: "inline"
      end
    end
  end

  private

  def load_items
    return unless @request.request_items

    inventory = nil
    if Event.read_events?(@request.organization)
      inventory = View::Inventory.new(@request.organization_id)
    end

    @request.request_items.map { |json| RequestItem.from_json(json, @request, inventory) }
  end

  helper_method \
    def filter_params
    return {} unless params.key?(:filters)

    params.require(:filters).permit(:by_request_item_id, :by_partner, :by_status)
  end
end
