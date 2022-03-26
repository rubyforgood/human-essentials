module Partners
  class BaseController < ApplicationController
    layout 'partners/application'

    skip_before_action :authenticate_user!
    skip_before_action :authorize_user
    before_action :authenticate_user!

    private

    def redirect_to_root
      redirect_to root_path
    end

    def current_partner_user
      current_user
    end

    helper_method :current_partner
    def current_partner
      current_partner_user.partner
    end

    def verify_status_in_diaper_base
      if current_partner.deactivated?
        flash[:alert] = 'Your account has been disabled, contact the organization via their email to reactivate'
        redirect_to partners_requests_path
      end
    end

    def authorize_verified_partners
      return if current_partner.verified?

      redirect_to partners_requests_path, notice: "Please review your application details and submit for approval in order to make a new request."
    end
  end
end
