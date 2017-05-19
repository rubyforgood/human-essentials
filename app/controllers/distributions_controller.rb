class DistributionsController < ApplicationController
  def print
    @distribution = Distribution.find(params[:id])
    # Do the prawn thing
  end

  def reclaim
    @distribution = Distribution.find(params[:id])
  end

  def index
    @distributions = Distribution.includes(:line_items).includes(:inventory).includes(:items).all
  end

  def create
    @distribution = Distribution.new(distribution_params)
    if (@distribution.save)
      redirect_to distribution_path(@distribution)
    else
      flash[:notice] = "An error occurred, try again?"
      render :new
    end
  end

  def new
    @distribution = Distribution.new
  end

  def show
    @distribution = Distribution.includes(:line_items).includes(:inventory).find(params[:id])
  end

  private

  def distribution_params
    params.require(:distribution).permit(:comment, :partner_id, :inventory_id)
  end
end
