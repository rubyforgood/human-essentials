class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :authenticate_user!

  def current_organization
    # FIXME: should be short_name so that we get "/pdx/blah" rather than "/123/blah"
    @organization ||= Organization.find_by(short_name: params[:organization_id])
  end
  helper_method :current_organization

  def organization_url_options(options={})
    options.merge(organization_id: current_organization.to_param)
  end
  helper_method :organization_url_options

  # override Rails' default_url_options to ensure organization_id is added to
  # each URL generated
  def default_url_options(options = {})
    if current_organization.present? && !options.has_key?(:organization_id)
      options[:organization_id] = current_organization.to_param
    elsif current_user && !current_user.is_superadmin? && current_user.organization.present?
      options[:organization_id] = current_user.organization.to_param
    end
    options
  end
end
