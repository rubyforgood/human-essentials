class AdjustmentsController < ApplicationController
  before_action :set_adjustment, only: [:show, :edit, :update, :destroy]

  # GET /adjustments
  # GET /adjustments.json
  def index
    @selected_location = filter_params[:at_location]
    @adjustments = current_organization.adjustments.filter(filter_params)

    @storage_locations = Adjustment.storage_locations_adjusted_for(current_organization).uniq
  end

  # GET /adjustments/1
  # GET /adjustments/1.json
  def show
  end

  # GET /adjustments/new
  def new
    @adjustment = current_organization.adjustments.new
    @adjustment.line_items.build
    @storage_locations = current_organization.storage_locations
    @items = current_organization.items.alphabetized
  end

  # POST /adjustments
  def create
    @adjustment = current_organization.adjustments.new(adjustment_params)

    if @adjustment.valid?
      @adjustment.storage_location.adjust!(@adjustment)

      if @adjustment.save
        redirect_to adjustments_path, notice: 'Adjustment was successfully created.'
      else
        render :new
      end
    else
      render :new
    end
  rescue Errors::InsufficientAllotment => ex
    flash[:alert] = ex.message
    render :new
  end

  private

  def set_adjustment
    @adjustment = current_organization.adjustments.find(params[:id])
  end

  def adjustment_params
    params.require(:adjustment).permit(:organization_id, :storage_location_id, :comment,
                                       line_items_attributes: [:item_id, :quantity, :_destroy])
  end

  def filter_params
    return {} unless params.has_key?(:filters)
    params.require(:filters).slice(:at_location)
  end
end
