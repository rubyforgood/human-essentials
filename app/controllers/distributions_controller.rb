class DistributionsController < ApplicationController
  def print
    @distribution = Distribution.find(params[:id])
    # Do the prawn thing
  end

  def reclaim
    @distribution = Distribution.find(params[:id])
  end

  def index
    @distributions = Distribution.includes(:line_items).includes(:storage_location).includes(:items).all
  end

  def create
    @distribution = Distribution.new(distribution_params.merge(organization: current_organization))
    if @distribution.save
      redirect_to distribution_path(@distribution, organization_id: current_organization.short_name)
    else
      flash[:notice] = "An error occurred, try again?"
      render :new
    end
  end

  def new
    @distribution = Distribution.new
  end

  def show
    @distribution = Distribution.includes(:line_items).includes(:storage_location).find(params[:id])
  end

  private

  def distribution_params
    params.require(:distribution).permit(:comment, :partner_id, :storage_location_id)
  end
end
