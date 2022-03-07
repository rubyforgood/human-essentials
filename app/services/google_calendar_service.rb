require "google/apis/calendar_v3"
require "signet"

class GoogleCalendarService
  include Rails.application.routes.url_helpers

  # @param [] session
  # @param organization_id [Integer]
  def initialize(session, organization_id)
    @organization_id = organization_id
    @service = Google::Apis::CalendarV3::CalendarService.new
    @service.client_options.application_name = "human-essentials"
    @service.authorization = Signet::OAuth2::Client.new(
      access_token: session['google.token'],
      refresh_token: session['google.refresh_token'],
      client_id: ENV["GOOGLE_OAUTH_CLIENT_ID"],
      client_secret: ENV["GOOGLE_OAUTH_CLIENT_SECRET"]
    )
  end

  # @return [Array<Google::Apis::CalendarV3::CalendarListEntry>]
  def list
    @service.list_calendar_lists.items.select { |i| %w(owner writer).include?(i.access_role)}
  end

  # @param distributions [Array<Distribution>]
  # @param calendar_id [String]
  def sync(distributions, calendar_id)
    distributions.each do |dist|
      event_obj = Google::Apis::CalendarV3::Event.new(
        creator: "human-essentials",
        description: dist.comment,
        end: dist.issued_at,
        start: dist.issued_at,
        location: pickup_day_distributions_path(organization_id: @organization_id, filters: { during: dist.issued_at.to_date }),
        summary: "Pickup from #{dist.partner.name}"
      )
      if dist.event_id
        event_obj.id = dist.event_id
        @service.update_event(calendar_id, dist.event_id, event_obj)
      else
        response = @service.insert_event(calendar_id, event_obj)
        dist.update!(event_id: response.event_id)
      end
    end
  end

end
