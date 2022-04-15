# for 2858 Partners View Pdfs
module Partners
  class DistributionsController < BaseController
    layout "partners/application"

    protect_from_forgery with: :exception

    def index
      @partner = current_partner
      @distributions = ::Partner.find(@partner.diaper_partner_id)
        .distributions.order(issued_at: :desc)

      @parent_org = Organization.find(@partner.diaper_bank_id)
    end
  end
end
