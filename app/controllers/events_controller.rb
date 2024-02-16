class EventsController < ApplicationController
  def index
    setup_date_range_picker

    @events = Event.for_organization(current_organization).
      class_filter(filter_params).
      includes(:eventable)
    if params.dig(:filters, :date_range).present?
      @events = @events.during(helpers.selected_range)
    end
    @items = current_organization.items
    @locations = current_organization.storage_locations

    respond_to do |format|
      format.html do
        @events = @events.page(params[:page])
      end
    end
  end

  def filter_params
    params.require(:filters).permit(:by_type, :by_storage_location)
  end
  helper_method :filter_params
end
