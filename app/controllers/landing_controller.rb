class LandingController < ApplicationController
  before_action :authenticate_user!
  skip_before_action :authorize_user

  def index
  end
end
