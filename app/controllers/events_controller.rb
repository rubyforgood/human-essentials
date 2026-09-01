class EventsController < ApplicationController
  # Migrated to the Ruby for Good design system (ADR 0011).
  layout "essentials_app"

  def index
    setup_date_range_picker

    @events = Event.for_organization(current_organization)
      .includes(:eventable, :user)
    # `.present?`, not a bare truth test. The row funnel's narrowing is a field in the filter bar's
    # form now, so clearing its chip submits `eventable_id=` -- an empty string, which is truthy in
    # Ruby and used to narrow the page to the events belonging to record "", i.e. none of them.
    @events = if params[:eventable_id].present?
      @events.where(eventable_id: params[:eventable_id],
        eventable_type: params[:eventable_type])
    else
      @events.class_filter(filter_params)
    end
    if params.dig(:filters, :date_range).present? || params[:eventable_id].blank?
      @events = @events.during(helpers.selected_range)
    end
    @items = current_organization.items.sort_by(&:name)
    @locations = current_organization.storage_locations

    respond_to do |format|
      format.html do
        @events = @events.page(params[:page]).per(Pagination::MEDIUM)
      end
    end
  end

  def filter_params
    params.fetch(:filters, {}).permit(:by_type, :by_storage_location, :by_item)
  end
  helper_method :filter_params
end
