module Partners
  class BaseController < ApplicationController
    layout 'partners/application'

    private

    def redirect_to_root
      redirect_to root_path
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
  end
end
