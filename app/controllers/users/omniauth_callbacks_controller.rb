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

  def google_oauth2_calendar
    token = request.env.dig("omniauth.auth", "credentials", "token")
    if token
      session["google.token"] = token
      session["google.refresh_token"] = request.env.dig("omniauth.auth", "credentials", "refresh_token")
      sign_in_and_redirect :calendar
    else
      redirect_to schedule_distributions_path, alert: "Authentication failed!"
    end
  end

  def after_sign_in_path_for(resource)
    if resource == :calendar
      google_calendar_list_path
    else
      super
    end
  end

end
