# This exists so that we can override some of the devise resource
class Partners::InvitationsController < Devise::InvitationsController
  layout "devise"

  skip_before_action :authorize_user
  skip_before_action :authenticate_user!
  # This one causes a redirect require_no_authentication
  skip_before_action :require_no_authentication

  def update
    raw_invitation_token = update_resource_params[:invitation_token]
    self.resource = accept_resource
    invitation_accepted = resource.errors.empty?

    yield resource if block_given?

    if invitation_accepted
      if redirect_to_legacy_partnerbase_app?
        redirect_to legacy_partnerbase_login_url
      elsif resource.class.allow_insecure_sign_in_after_accept
        flash_message = resource.active_for_authentication? ? :updated : :updated_not_active
        set_flash_message :notice, flash_message if is_flashing_format?
        resource.after_database_authentication
        sign_in(resource_name, resource)
        respond_with resource, location: after_accept_path_for(resource)
      else
        set_flash_message :notice, :updated_not_active if is_flashing_format?
        respond_with resource, location: new_session_path(resource_name)
      end
    else
      resource.invitation_token = raw_invitation_token
      respond_with_navigational(resource) { render :edit }
    end
  end

  private

  def redirect_to_legacy_partnerbase_app?
    !Rails.env.development?
  end

  def legacy_partnerbase_login_url
    ENV.fetch("PARTNER_BASE_URL") + "/users/sign_in"
  end
end
