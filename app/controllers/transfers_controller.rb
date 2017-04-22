class TransfersController < ApplicationController
  def index
  	@transfers = Transfer.all
  end

  def create
    @transfer = Transfer.create(transfer_params)
    redirect_to transfer_path(@transfer)
  end

  def new
  	@transfer = Transfer.new
  end

  def show
  	@transfer = Transfer.new
  end

private
  def transfer_params
  	params.require(:transfer).permit(:from_id, :to_id)
  end
end
