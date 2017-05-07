class TransfersController < ApplicationController
  def index
  	@transfers = Transfer.all
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
  end

  def show
  	@transfer = Transfer.new
  end

private
  def transfer_params
  	params.require(:transfer).permit(:from_id, :to_id, :comment)
  end
end
