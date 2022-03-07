class GoogleCalendarController < ApplicationController
  def list
    @calendars = GoogleCalendarService.new(session).list
  end

  def sync
    distributions = current_organization.distributions
    calendar_id = params[:calendar_id]
    GoogleCalendarService.new(session).sync(distributions, calendar_id)
  end

  rescue_from Google::Apis::AuthorizationError do
    redirect_to user_google_oauth2_calendar_omniauth_authorize_path
  end

end
