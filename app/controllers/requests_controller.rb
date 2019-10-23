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
    @request_items = get_items(@request.request_items)
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

  # TODO: This should probably be made private
  def get_items(request_items)
    # using Struct vs Hash so we can use dot notation in the view
    return unless request_items

    Struct.new('Item', :name, :quantity, :on_hand)
    request_items.map do |key|
      Struct::Item.new(Item.find(key["item_id"]).name, key["quantity"], sum_inventory(Item.find(key["item_id"])))
    end
  end

  # TODO: This should probably be made private
  def sum_inventory(key)
    current_organization.inventory_items.where(item_id: key).sum(:quantity)
  end

  # TODO: kick off job to send email
  def destroy
    ActiveRecord::Base.transaction do
      Request.find(params[:id]).destroy!
    end
    flash[:notice] = "Request #{params[:id]} has been removed!"
    redirect_to requests_path
  end
end
