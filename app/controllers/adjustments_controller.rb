# Provides limited CRUD for Adjustments, which are the way that Diaper Banks fix incorrect inventory totals at Storage Locations
class AdjustmentsController < ApplicationController
  # GET /adjustments
  # GET /adjustments.json
  def index
    @selected_location = filter_params[:at_location]
    @adjustments = current_organization.adjustments.class_filter(filter_params)

    @storage_locations = Adjustment.storage_locations_adjusted_for(current_organization).uniq
  end

  # GET /adjustments/1
  # GET /adjustments/1.json
  def show
    @adjustment = current_organization.adjustments.find(params[:id])
  end

  # GET /adjustments/new
  def new
    @adjustment = current_organization.adjustments.new
    @adjustment.line_items.build
    @storage_locations = current_organization.storage_locations
    @items = current_organization.items.active.alphabetized
  end

  # POST /adjustments
  def create
    @adjustment = current_organization.adjustments.new(adjustment_params)

    if @adjustment.valid? && @adjustment.save
      increasing_adjustment, decreasing_adjustment = @adjustment.split_difference
      ActiveRecord::Base.transaction do
        @adjustment.storage_location.increase_inventory increasing_adjustment
        @adjustment.storage_location.decrease_inventory decreasing_adjustment
      end

      redirect_to adjustment_path(@adjustment), notice: "Adjustment was successful."
    else
      flash[:error] = @adjustment.errors.collect { |model, message| "#{model}: " + message }.join("<br />".html_safe)
      load_form_collections
      render :new
    end
  rescue Errors::InsufficientAllotment => ex
    flash[:error] = ex.message
    load_form_collections
    render :new
  end

  private

  def load_form_collections
    @storage_locations = current_organization.storage_locations
    @items = current_organization.items.alphabetized
  end

  def adjustment_params
    params.require(:adjustment).permit(:organization_id, :storage_location_id, :comment,
                                       line_items_attributes: %i(item_id quantity _destroy))
  end

  def filter_params
    return {} unless params.key?(:filters)

    params.require(:filters).slice(:at_location)
  end
end
