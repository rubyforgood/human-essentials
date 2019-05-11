# Base Controller. There is some magic in here that handles organization-scoping for routes
class ApplicationController < ActionController::Base
  include DateHelper

  protect_from_forgery with: :exception
  before_action :authenticate_user!
  before_action :authorize_user
  before_action :log_active_user
  before_action :swaddled
  before_action :configure_permitted_parameters, if: :devise_controller?

  rescue_from ActiveRecord::RecordNotFound, with: :not_found!

  def current_organization
    @organization ||= Organization.find_by(short_name: params[:organization_id]) || current_user&.organization
  end
  helper_method :current_organization

  def organization_url_options(options = {})
    options.merge(organization_id: current_organization.to_param)
  end
  helper_method :organization_url_options

  # override Rails' default_url_options to ensure organization_id is added to
  # each URL generated
  def default_url_options(options = {})
    if current_organization.present? && !options.key?(:organization_id)
      options[:organization_id] = current_organization.to_param
    elsif current_user && !current_user.super_admin? && current_user.organization.present?
      options[:organization_id] = current_user.organization.to_param
    elsif current_user&.super_admin?
      # FIXME: This *might* not be the best way to approach this...
      options[:organization_id] = "admin"
    end
    options
  end

  def authorize_user
    # params[:controller].include?("admin") ||
    verboten! unless params[:controller].include?("devise") || current_user.super_admin? || current_organization.id == current_user.organization_id
  end

  def log_active_user
    if current_user && should_update_last_request_at?
      # rubocop:disable Rails/SkipsModelValidations
      # we don't want the user record to validate or run callbacks when we're tracking activity
      current_user.update_columns(last_request_at: Time.now.utc)
      # rubocop:enable Rails/SkipsModelValidations
    end
  end

  def should_update_last_request_at?
    current_user.last_request_at.nil? || last_request_logged_more_than_10_minutes_ago?
  end

  def last_request_logged_more_than_10_minutes_ago?
    current_user.last_request_at.utc < 10.minutes.ago.utc
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

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:account_update, keys: [:name])
  end
end
