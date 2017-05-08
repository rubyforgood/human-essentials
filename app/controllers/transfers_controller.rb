class TransfersController < ApplicationController
  def index
  	@transfers = Transfer.includes(:containers).includes(:from).includes(:to).all
  end

  def create
    @transfer = Transfer.new(transfer_params)
    if (@transfer.save)
      redirect_to transfer_path(@transfer)
    else
      flash[:notice] = "There was an error, try again?"
      render :new
    end
  end

  def new
  	@transfer = Transfer.new
    @inventories = Inventory.all
    @items = Item.all
  end

  def show
  	@transfer = Transfer.includes(:containers).includes(:from).includes(:to).includes(:items).find(params[:id])
    @total = @transfer.total_quantity
    @containers = @transfer.sorted_containers
  end

private
  def transfer_params
  	params.require(:transfer).permit(:from_id, :to_id, :comment)
  end
end
