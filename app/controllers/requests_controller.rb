# Provides Read-only access to Requests, which are created via an API. Requests are transformed into Distributions.
class RequestsController < ApplicationController
  # Migrated to the Ruby for Good design system (ADR 0011).
  layout "essentials_app"

  def index
    setup_date_range_picker

    @requests_info = View::Requests.new(params: params, organization: current_organization, helpers: helpers)

    respond_to do |format|
      format.html
      format.csv { send_data Exports::ExportRequestService.new(@requests_info.requests, current_organization).generate_csv, filename: "Requests-#{Time.zone.today}.csv" }
    end
  end

  def show
    @request_info = View::RequestInfo.new(params:, organization: current_organization)
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

  # Picklists for the requests the reader selected. `print_unfulfilled` prints everything that is
  # outstanding; this prints the set they picked, which is the case that used to mean opening each
  # row's menu in turn.
  #
  # Scoped through `current_organization.requests` like every other action here, so an id from
  # another organization selects nothing rather than leaking a picklist.
  def print_picklists
    requests = current_organization
      .requests
      .includes(:item_requests, partner: [:profile])
      .where(id: params[:ids].presence || [])
      .order(created_at: :desc)

    if requests.empty?
      redirect_back_or_to(requests_path, alert: "Select at least one request to print picklists for.")
      return
    end

    pdf = PicklistsPdf.new(current_organization, requests)
    send_data pdf.compute_and_render,
      filename: format("Picklists_%s.pdf", Time.current.to_fs(:long)),
      type: "application/pdf",
      disposition: "inline"
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
