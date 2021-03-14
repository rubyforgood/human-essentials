# This exists so that we can override some of the devise resource
class Partners::InvitationsController < Devise::InvitationsController
  layout "devise"

  skip_before_action :authorize_user
  skip_before_action :authenticate_user!
  # This one causes a redirect require_no_authentication
  skip_before_action :require_no_authentication

  #
  # This update action was added to override and add new redirection behaviors
  # when accepting an invitation. Namely, we want do not want to redirect
  # newly invited users to the unfinished version of partnerbase within
  # this repo. Instead we'll want to redirect them to the legacy partnerbase
  # application until we are ready.
  #
  # **Once we've migrated all users to partnerbase within this repo,
  # we can erase this file entirely**
  #
  # Here is a reference of the original endpoint code that that was modified
  # https://github.com/scambra/devise_invitable/blob/f6a308d427de1bd263337be4a334f586962ce589/app/controllers/devise/invitations_controller.rb#L45-L68
  #
  def update
    raw_invitation_token = update_resource_params[:invitation_token]
    # The self.resource is a partner_user record
    self.resource = accept_resource
    invitation_accepted = resource.errors.empty?

    yield resource if block_given?

    if invitation_accepted
      if redirect_to_legacy_partnerbase_app?
        # Redirect to the legacy partnerbase login url outside of development
        # to avoid them from going to the unfinished partnerbase in the repo.
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

