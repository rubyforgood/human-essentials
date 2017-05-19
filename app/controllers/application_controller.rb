class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :authenticate_user!

  def current_organization
    # FIXME: should be short_name so that we get "/pdx/blah" rather than "/123/blah"
  	@organization ||= Organization.find_by(short_name: params[:organization_id])
  end
end
