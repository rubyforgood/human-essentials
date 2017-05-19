class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :authenticate_user!

  def current_organization
    # FIXME: should be short_name so that we get "/pdx/blah" rather than "/123/blah"
  	@organization ||= Organization.find_by(short_name: params[:organization_id])
  end

  def organization_url_options(options={})
    options.merge(organization_id: current_organization.to_param)
  end
  helper_method :organization_url_options

  # override Rails' default_url_options
  def default_url_options(options = {})
    if current_organization.present? && options[:organization_id].nil?
      options[:organization_id] = current_organization.to_param
    end
    options
  end
end
