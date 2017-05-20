class DistributionsController < ApplicationController
  def print
    @distribution = Distribution.find(params[:id])
    # Do the prawn thing
  end

  def reclaim
    @distribution = Distribution.find(params[:id])
    @distribution.storage_location.reclaim!(@distribution)

    flash[:notice] = "Distribution #{@distribution.id} has been reclaimed!"
    redirect_to distributions_path

  end

  def index
    @distributions = Distribution.includes(:line_items).includes(:storage_location).includes(:items).all
  end

  def create
    @distribution = Distribution.new(distribution_params.merge(organization: current_organization))
    if @distribution.save

      @distribution.storage_location.distribute!(@distribution)
      redirect_to distributions_path
    else
      flash[:notice] = "An error occurred, try again?"
      render :new
    end
  end

  def new
    @distribution = Distribution.new
    @distribution.line_items.build
    @items = Item.alphabetized
    @storage_locations = StorageLocation.all
  end

  def show
    @distribution = Distribution.includes(:line_items).includes(:storage_location).find(params[:id])
  end

  private

  def distribution_params
    params.require(:distribution).permit(:comment, :partner_id, :storage_location_id, line_items_attributes: [:item_id, :quantity, :_destroy])
  end
end
