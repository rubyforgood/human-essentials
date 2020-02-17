# Provides limited CRUD for Adjustments, which are the way that Diaper Banks fix incorrect inventory totals at Storage Locations
class AdjustmentsController < ApplicationController
  # GET /adjustments
  # GET /adjustments.json

  def index
    setup_date_range_picker

    @selected_location = filter_params[:at_location]
    @selected_user = filter_params[:by_user]
    @adjustments = current_organization.adjustments
                                       .order(created_at: :desc)
                                       .class_filter(filter_params)
                                       .during(helpers.selected_range)
    @paginated_adjustments = @adjustments.page(params[:page])

    @storage_locations = Adjustment.storage_locations_adjusted_for(current_organization).uniq
    @users = current_organization.users
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
    @adjustment.user_id = current_user.id

    if @adjustment.valid? && @adjustment.save
      increasing_adjustment, decreasing_adjustment = @adjustment.split_difference
      ActiveRecord::Base.transaction do
        @adjustment.storage_location.increase_inventory increasing_adjustment
        @adjustment.storage_location.decrease_inventory decreasing_adjustment
      end
      flash[:notice] = "Adjustment was successful."
      redirect_to adjustment_path(@adjustment)
    else
      flash[:error] = @adjustment.errors.collect { |model, message| "#{model}: " + message }.join("<br />".html_safe)
      load_form_collections
      render :new
    end
  rescue Errors::InsufficientAllotment => e
    flash[:error] = e.message
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

    params.require(:filters).slice(:at_location, :by_user)
  end
end
