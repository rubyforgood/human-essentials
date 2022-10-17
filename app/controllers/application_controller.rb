# Base Controller. There is some magic in here that handles organization-scoping for routes
class ApplicationController < ActionController::Base
  add_flash_types :error
  include DateHelper

  protect_from_forgery with: :exception
  before_action :authenticate_user!
  before_action :authorize_user
  before_action :log_active_user
  before_action :swaddled
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :set_paper_trail_whodunnit
  helper_method :current_role

  rescue_from ActiveRecord::RecordNotFound, with: :not_found!

  def current_organization
    @current_organization ||= Organization.find_by(short_name: params[:organization_id]) || current_user&.organization
  end
  helper_method :current_organization

  def current_role
    role = Role.find_by(id: session[:current_role]) || UsersRole.current_role_for(current_user)
    session[:current_role] = role&.id

    role
  end

  def organization_url_options(options = {})
    options.merge(organization_id: current_organization.to_param)
  end
  helper_method :organization_url_options

  # override Rails' default_url_options to ensure organization_id is added to
  # each URL generated
  def default_url_options(options = {})
    # Early return if the request is not authenticated and no
    # current_user is defined
    return options if current_user.blank?

    if current_organization.present? && !options.key?(:organization_id)
      options[:organization_id] = current_organization.to_param
    elsif current_role.name == Role::ORG_ADMIN.to_s
      options[:organization_id] = current_user.organization.to_param
    elsif current_role.name == Role::SUPER_ADMIN.to_s
      # FIXME: This *might* not be the best way to approach this...
      options[:organization_id] = "admin"
    end
    options
  end

  def dashboard_path_from_current_role
    if current_role.name == Role::SUPER_ADMIN.to_s
      admin_dashboard_path
    elsif current_role.name == Role::PARTNER.to_s
      partners_dashboard_path
    elsif current_user.organization
      dashboard_path(current_user.organization)
    else
      root_path
    end
  end

  def authorize_user
    return unless params[:controller] # part of omniauth controller flow
    verboten! unless params[:controller].include?("devise") ||
      current_user.has_role?(Role::SUPER_ADMIN) ||
      current_user.has_role?(Role::ORG_USER, current_organization) ||
      current_user.has_role?(Role::ORG_ADMIN, current_organization)
  end

  def authorize_admin
    verboten! unless current_user.has_role?(Role::SUPER_ADMIN) ||
      current_user.has_role?(Role::ORG_ADMIN, current_organization)
  end

  def log_active_user
    if current_user && should_update_last_request_at?
      # we don't want the user record to validate or run callbacks when we're tracking activity
      current_user.update_columns(last_request_at: Time.now.utc)

    end
  end

  def should_update_last_request_at?
    current_user.last_request_at.nil? || last_request_logged_more_than_10_minutes_ago?
  end

  def last_request_logged_more_than_10_minutes_ago?
    current_user.last_request_at.utc < 10.minutes.ago.utc
  end

  def enable_turbo!
    @turbo = true
  end

  def not_found!
    respond_to do |format|
      format.html { render template: "errors/404", layout: "layouts/application", status: :not_found }
      format.json { render body: nil, status: :not_found }
    end
  end

  def verboten!
    respond_to do |format|
      format.html { redirect_to dashboard_path, flash: { error: "Access Denied." } }
      format.json { render body: nil, status: :forbidden }
    end
  end

  def omgwtfbbq!
    respond_to do |format|
      format.html { render template: "errors/500", layout: "layouts/error", status: :internal_server_error }
      format.json { render nothing: true, status: :internal_server_error }
    end
  end

  def swaddled
    response.headers["swaddled-by"] = "rubyforgood"
  end

  protected

  def setup_date_range_picker
    @selected_date_interval = helpers.selected_interval
    @selected_date_range = helpers.selected_interval.map { |d| d.to_fs(:long) }.join(" - ")
    @selected_date_range_label = helpers.date_range_label
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:account_update, keys: [:name])
  end
end
