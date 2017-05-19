class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  def current_organization
  	@organization ||= Organization.find_by(id: params[:organization_id])
  end
end
