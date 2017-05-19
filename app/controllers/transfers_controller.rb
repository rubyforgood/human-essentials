class TransfersController < ApplicationController
  def index
    @transfers = Transfer.includes(:line_items).includes(:from).includes(:to).all
  end

  def create
    @transfer = Transfer.new(transfer_params.merge({ organization_id: current_organization.id }) )
    if (@transfer.save)
      redirect_to transfer_path(organization_id: current_organization.short_name, id: @transfer)
    else
      flash[:notice] = "There was an error, try again?"
      render :new
    end
  end

  def new
    @transfer = Transfer.new
    @storage_locations = StorageLocation.all
    @items = Item.all
  end

  def show
    @transfer = Transfer.includes(:line_items).includes(:from).includes(:to).includes(:items).find(params[:id])
    @total = @transfer.total_quantity
    @line_items = @transfer.sorted_line_items
  end

  private

  def transfer_params
    params.require(:transfer).permit(:from_id, :to_id, :comment)
  end
end
