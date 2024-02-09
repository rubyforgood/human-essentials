class EventsController < ApplicationController
  def index
    setup_date_range_picker

    @events = Event.for_organization(current_organization).during(helpers.selected_range)
    @items = current_organization.items
    @locations = current_organization.storage_locations

    respond_to do |format|
      format.html do
        @events = @events.page(params[:page])
      end
    end
  end

  def filter_params
    {}
  end
  helper_method :filter_params
end
