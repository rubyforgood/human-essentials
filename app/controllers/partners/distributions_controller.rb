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

    def print
      distribution = Distribution.find(params[:id])
      respond_to do |format|
        format.any do
          pdf = DistributionPdf.new(distribution.organization, distribution)
          send_data pdf.render,
            filename: format("%s %s.pdf", distribution.partner.name, sortable_date(distribution.created_at)),
            type: "application/pdf",
            disposition: "inline"
        end
      end
    end
  end
end
