module Partners
  class DashboardsController < BaseController
    layout 'partners/application'

    protect_from_forgery with: :exception

    def index; end

    def show
      @partner = current_partner
      @partner_requests = @partner.requests.order(created_at: :desc).limit(10)
      @upcoming_distributions = ::Partner.find(@partner.diaper_partner_id)
                                         .distributions.order(issued_at: :desc)
                                         .where('issued_at >= ?', Time.zone.today)
      @distributions = ::Partner.find(@partner.diaper_partner_id)
                                .distributions.order(issued_at: :desc)
                                .where('issued_at < ?', Time.zone.today)
                                .limit(5)

      @parent_org = Organization.find(@partner.essentials_bank_id)

      @requests_in_progress = @parent_org
                              .ordered_requests
                              .where(partner: @partner.diaper_partner_id)
                              .where(status: 0)

      @families = @partner.families
      @children = @partner.children
    end
  end
end
