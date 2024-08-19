module Partners
  class BaseController < ApplicationController
    layout 'partners/application'

    before_action :require_partner

    private

    def redirect_to_root
      redirect_to root_path
    end

    def require_partner
      unless current_partner
        respond_to do |format|
          format.html { redirect_to dashboard_path, flash: {error: "Logged in user is not set up as a 'partner'."} }
          format.json { render body: nil, status: :forbidden }
        end
      end
    end

    def verify_partner_is_active
      if current_partner.deactivated?
        flash[:alert] = 'Your account has been disabled, contact the organization via their email to reactivate'
        redirect_to partners_requests_path
      end
    end

    def authorize_verified_partners
      return if current_partner.approved?

      redirect_to partners_requests_path, notice: "Please review your application details and submit for approval in order to make a new request."
    end

    def not_found!
      respond_to do |format|
        format.html { render template: "errors/404", layout: "layouts/partners/application", status: :not_found }
        format.json { render body: nil, status: :not_found }
      end
    end
  end
end
