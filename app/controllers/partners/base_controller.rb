module Partners
  class BaseController < ApplicationController
    layout 'partners/application'

    before_action :redirect_to_root, unless: -> { Rails.env.test? || Flipper.enabled?(:onebase) }
    skip_before_action :authenticate_user!
    skip_before_action :authorize_user
    before_action :authenticate_partner_user!

    private

    def redirect_to_root
      redirect_to root_path
    end

    helper_method :current_partner
    def current_partner
      current_partner_user.partner
    end
  end
end
