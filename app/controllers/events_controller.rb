class EventsController < ApplicationController
  def index
    setup_date_range_picker

    @events = Event.for_organization(current_organization)
      .during(helpers.selected_range)
      .includes(:eventable, :user)
    @events = if params[:eventable_id]
      @events.where(eventable_id: params[:eventable_id],
        eventable_type: params[:eventable_type])
    else
      @events.class_filter(filter_params)
    end
    if params.dig(:filters, :date_range).present?
      @events = @events.during(helpers.selected_range)
    end
    @items = current_organization.items.sort_by(&:name)
    @locations = current_organization.storage_locations

    respond_to do |format|
      format.html do
        @events = @events.page(params[:page])
      end
    end
  end

  def filter_params
    params.fetch(:filters, {}).permit(:by_type, :by_storage_location, :by_item)
  end
  helper_method :filter_params
end
