class LandingController < ApplicationController
  skip_before_action :authorize_user
  skip_before_action :authenticate_user!

  def index
    redirect_to dashboard_url(current_user.organization) if current_user
  end
end
