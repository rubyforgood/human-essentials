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
    @request_items = get_items(@request.request_items)
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

  def get_items(request_items)
    array = []
    request_items.each do |key, quantity|
      array << {
        name: @request.items_hash[key].name,
        quantity: quantity,
        on_hand: sum_inventory(key)
      }
    end
    array
  end

  def sum_inventory(partner_key)
    current_organization.inventory_items.by_partner_key(partner_key).sum(:quantity)
  end

end
