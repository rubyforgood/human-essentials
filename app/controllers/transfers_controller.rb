class TransfersController < ApplicationController
  def index
    @transfers = current_organization.transfers.includes(:line_items).includes(:from).includes(:to).filter(filter_params)
    @selected_from = filter_params[:from_location]
    @selected_to = filter_params[:to_location]
    @from_storage_locations = Transfer.storage_locations_transferred_from_in(current_organization)
    @to_storage_locations = Transfer.storage_locations_transferred_to_in(current_organization)
  end

  def create
    @transfer = current_organization.transfers.new(transfer_params)

    if @transfer.valid?
      @transfer.from.move_inventory!(@transfer)

      if @transfer.save
        redirect_to transfers_path, notice: "Transfer was successfully created."
      else
        flash[:error] = "There was an error, try again?"
        render :new
      end
    else
      flash[:error] = "There was an error creating the transfer"
      @storage_locations = current_organization.storage_locations.alphabetized
      @items = current_organization.items.alphabetized
      @transfer.line_items.build if @transfer.line_items.empty?
      render :new
    end
  rescue Errors::InsufficientAllotment => ex
    flash[:error] = ex.message
    @storage_locations = current_organization.storage_locations.alphabetized
    @items = current_organization.items.alphabetized
    @transfer.line_items.build if @transfer.line_items.empty?
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
                                     line_items_attributes: %i(item_id quantity _destroy))
  end

  def filter_params
    return {} unless params.key?(:filters)
    params.require(:filters).slice(:from_location, :to_location)
  end
end
