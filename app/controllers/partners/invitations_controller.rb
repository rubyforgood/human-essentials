# This exists so that we can override some of the devise resource
class Partners::InvitationsController < Devise::InvitationsController
  layout "devise_partner_users"

  skip_before_action :authorize_user
  skip_before_action :authenticate_user!
  # This one causes a redirect require_no_authentication
  skip_before_action :require_no_authentication
end

