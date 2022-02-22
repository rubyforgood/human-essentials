# This exists so that we can override some of the devise resource
class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  skip_before_action :authorize_user

  def google_oauth2
    user = User.from_omniauth(request.env["omniauth.auth"])

    session["google.token"] = request.env.dig("omniauth.auth", "credentials", "token")
    session["google.refresh_token"] = request.env.dig("omniauth.auth", "credentials", "refresh_token")
    if user
      flash[:notice] = I18n.t "devise.omniauth_callbacks.success", kind: "Google"
      sign_in_and_redirect user, event: :authentication
    else
      redirect_to new_user_registration_url, alert: "Authentication failed: User not found!"
    end
  end
end
