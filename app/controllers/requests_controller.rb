# Provides Read-only access to Requests, which are created via an API. Requests are transformed into Distributions.
class RequestsController < ApplicationController
  def index
    setup_date_range_picker

    @paginated_requests = current_organization
                          .ordered_requests
                          .during(helpers.selected_range)
                          .page(params[:page])
    respond_to do |format|
      format.html
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

  # TODO: kick off job to send email
  def destroy
    ActiveRecord::Base.transaction do
      Request.find(params[:id]).destroy!
    end
    flash[:notice] = "Request #{params[:id]} has been removed!"
    redirect_to requests_path
  end

  private

  def load_items
    return unless @request.request_items

    @request.request_items.map { |json| RequestItem.from_json(json, current_organization) }
  end
end
