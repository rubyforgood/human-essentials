class RequestsController < ApplicationController
  def index
    @requests = current_organization.ordered_requests
    respond_to do |format|
      format.html
    end
  end

  def show
    @request = Request.find(params[:id])
    @items = @request.items_hash
  end

  # Clicking the "Fullfill" button will set the the request to fulfilled
  # and will move the user to the new distribution page with a
  # pre-filled distribution containing all the requested items.
  def fullfill
    request = Request.find(params[:id])
    request.update(status: "Fulfilled")
    flash[:notice] = "Request marked as fulfilled"
    redirect_to new_distribution_path(request_id: request.id)
  end
end
