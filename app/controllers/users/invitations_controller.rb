# This exists so that we can override some of the devise resource
class Users::InvitationsController < Devise::SessionsController
  layout "devise"
end
