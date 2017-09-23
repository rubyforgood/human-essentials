class TransfersController < ApplicationController
  def index
    @transfers = current_organization.transfers.includes(:line_items).includes(:from).includes(:to)
    @categories = Item.categories
  end

  def create
    @transfer = current_organization.transfers.new(transfer_params)

    if @transfer.valid?
      @transfer.from.move_inventory!(@transfer)

      if @transfer.save
        redirect_to transfer_path(organization_id: current_organization.short_name, id: @transfer)
      else
        flash[:notice] = "There was an error, try again?"
        render :new
      end
    else
      flash[:notice] = "There was an error creating the transfer"
      render :new
    end
  rescue Errors::InsufficientAllotment => ex
    flash[:notice] = ex.message
    render :new
  end

  def new
    @transfer = current_organization.transfers.new
    @transfer.line_items.build
    @storage_locations = current_organization.storage_locations.alphabetized
    @items = current_organization.items.alphabetized
  end

  def show
    @transfer = current_organization.transfers.includes(:line_items).includes(:from).includes(:to).includes(:items).find(params[:id])
    @total = @transfer.line_items.total
    @line_items = @transfer.line_items.sorted
  end

  private

  def transfer_params
    params.require(:transfer).permit(:from_id, :to_id, :comment,
                                     line_items_attributes: [:item_id, :quantity, :_destroy])
  end

  def filter_params
    return {} unless params.has_key?(:filters)
    params.require(:filters).slice(:in_category)
  end
end
