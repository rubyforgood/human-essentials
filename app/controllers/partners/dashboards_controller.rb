module Partners
  class DashboardsController < BaseController
    layout 'partners/application'

    protect_from_forgery with: :exception

    def index; end

    def show
      @partner = current_partner
      @partner_requests = @partner.requests.order(created_at: :desc).limit(10)
      @upcoming_distributions = @partner.distributions.order(issued_at: :desc)
                                        .where('issued_at >= ?', Time.zone.today)
      @distributions = @partner.distributions.order(issued_at: :desc)
                               .where('issued_at < ?', Time.zone.today)
                               .limit(5)

      @parent_org = Organization.find(@partner.organization_id)

      @requests_in_progress = @parent_org
                              .ordered_requests
                              .where(partner: @partner.id)
                              .where(status: 0)

      @families = @partner.families
      @children = @partner.children
      if Event.read_events?(@partner.organization)
        @inventory = View::Inventory.new(@partner.organization_id)
      end

      @broadcast_announcements = BroadcastAnnouncement.filter_announcements(@parent_org)
    end
  end
end
