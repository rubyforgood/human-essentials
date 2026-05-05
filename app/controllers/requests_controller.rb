# Provides Read-only access to Requests, which are created via an API. Requests are transformed into Distributions.
class RequestsController < ApplicationController
  def index
    setup_date_range_picker

    @request_info = View::Requests.from_params(params: params, organization: current_organization, helpers: helpers)

    respond_to do |format|
      format.html
      format.csv { send_data Exports::ExportRequestService.new(@request_info.requests).generate_csv, filename: "Requests-#{Time.zone.today}.csv" }
    end
  end

  def show
    @request = current_organization.requests.find(params[:id])
    @item_requests = @request.item_requests.includes(:item)

    @inventory = View::Inventory.new(@request.organization_id)
    @default_storage_location = @request.partner.default_storage_location_id || @request.organization.default_storage_location
    @location = StorageLocation.find_by(id: @default_storage_location)

    @custom_units = Flipper.enabled?(:enable_packs) && @request.item_requests.any? { |item| item.request_unit }
  end

  # Clicking the "New Distribution" button will set the the request to started
  # and will move the user to the new distribution page with a
  # pre-filled distribution containing all the requested items.
  def start
    request = current_organization.requests.find(params[:id])
    begin
      request.status_started!
      flash[:notice] = "Request started"
      redirect_to new_distribution_path(request_id: request.id)
    rescue ActiveRecord::RecordInvalid
      flash[:alert] = request.errors.full_messages.to_sentence
      redirect_to request_path(request)
    end
  end

  def print_picklist
    request = current_organization
      .requests
      .includes(:item_requests, partner: [:profile])
      .find(params[:id])

    respond_to do |format|
      format.any do
        pdf = PicklistsPdf.new(current_organization, [request])
        send_data pdf.compute_and_render,
          filename: format("Picklists_%s.pdf", Time.current.to_fs(:long)),
          type: "application/pdf",
          disposition: "inline"
      end
    end
  end

  def print_unfulfilled
    requests = current_organization
      .requests
      .includes(:item_requests, partner: [:profile])
      .where(status: [:pending, :started])
      .order(created_at: :desc)
      .during(helpers.selected_range)
      .class_filter(filter_params)

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

  helper_method \
    def filter_params
    return {} unless params.key?(:filters)

    params.require(:filters).permit(:by_request_item_id, :by_partner, :by_status, :by_request_type)
  end
end
