# This exists so that we can override some of the devise resource
class Users::InvitationsController < Devise::SessionsController
  skip_before_action :require_organization

  layout "devise"
end
