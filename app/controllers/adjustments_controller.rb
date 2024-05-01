# Provides limited CRUD for Adjustments, which are the way that Essentials Banks fix incorrect inventory totals at Storage Locations
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

    respond_to do |format|
      format.html
      format.csv { send_data Adjustment.generate_csv(@adjustments), filename: "Adjustments-#{Time.zone.today}.csv" }
    end
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
    @storage_locations = current_organization.storage_locations.active_locations
    @items = current_organization.items.loose.active.alphabetized
  end

  # POST /adjustments
  def create
    result = AdjustmentCreateService.new(adjustment_params.merge(organization: current_organization, user: current_user)).call
    @adjustment = result.adjustment
    if @adjustment.errors.none?
      flash[:notice] = "Adjustment was successful."
      redirect_to adjustment_path(@adjustment)
    else
      flash[:error] = @adjustment.errors.collect { |error| "#{error.attribute}: " + error.message }.join("<br />".html_safe)
      load_form_collections
      render :new
    end
  end

  private

  def load_form_collections
    @storage_locations = current_organization.storage_locations.active_locations
    @items = current_organization.items.loose.alphabetized
  end

  def adjustment_params
    params.require(:adjustment).permit(:organization_id, :storage_location_id, :comment,
                                       line_items_attributes: %i(item_id quantity _destroy))
  end

  helper_method \
    def filter_params
    return {} unless params.key?(:filters)

    params.require(:filters).permit(:at_location, :by_user)
  end
end
