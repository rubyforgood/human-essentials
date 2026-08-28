# Base Controller. There is some magic in here that handles organization-scoping for routes
class ApplicationController < ActionController::Base
  add_flash_types :error
  include DateHelper

  protect_from_forgery with: :exception
  before_action :authenticate_user!
  before_action :authorize_user
  before_action :require_organization, unless: :devise_controller?
  before_action :log_active_user
  before_action :swaddled
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :set_paper_trail_whodunnit
  helper_method :current_role

  rescue_from ActiveRecord::RecordNotFound, with: :not_found!

  rescue_from ActionController::InvalidAuthenticityToken, with: :session_expired

  def session_expired
    flash[:error] = "Your session expired. This could be due to leaving a page open for a long time, or having multiple tabs open. Try resubmitting."
    redirect_back_or_to(root_path)
  end

  def current_organization
    return @current_organization if instance_variable_defined? :@current_organization

    @current_organization = if !current_role
      nil
    elsif current_role.resource.is_a?(Organization)
      current_role.resource
    else
      Organization.find_by(id: params[:organization_id])
    end
  end
  helper_method :current_organization

  def current_partner
    return @current_partner if instance_variable_defined? :@current_partner

    @current_partner = if !current_role || current_role.name.to_sym != Role::PARTNER
      nil
    else
      current_role.resource
    end
  end
  helper_method :current_partner

  def current_role
    return @role if instance_variable_defined? :@role

    @role = if !current_user
      nil
    else
      Role.find_by(id: session[:current_role]) || UsersRole.current_role_for(current_user)
    end
  end

  def dashboard_path_from_current_role
    return root_path if current_role.blank?

    if current_role.name == Role::SUPER_ADMIN.to_s
      admin_dashboard_path
    elsif current_role.name == Role::PARTNER.to_s
      partners_dashboard_path
    elsif current_user.organization
      dashboard_path
    else
      "/403"
    end
  end
  helper_method :dashboard_path_from_current_role

  def authorize_user
    return unless params[:controller] # part of omniauth controller flow
    verboten! unless params[:controller].include?("devise") ||
      current_user.has_cached_role?(Role::SUPER_ADMIN) ||
      current_user.has_cached_role?(Role::ORG_USER, current_organization) ||
      current_user.has_cached_role?(Role::ORG_ADMIN, current_organization) ||
      current_user.has_cached_role?(Role::PARTNER, current_partner)
  end

  def authorize_admin
    verboten! unless current_user.has_cached_role?(Role::SUPER_ADMIN) ||
      current_user.has_cached_role?(Role::ORG_ADMIN, current_organization)
  end

  def require_organization
    return if current_organization

    respond_to do |format|
      format.html { redirect_to dashboard_path_from_current_role, flash: {error: "That screen is not available. Please try again as a bank."} }
      format.json { render body: nil, status: :forbidden }
    end
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

  # One convention for a validation failure: the error summary above the form. It names each
  # field and links to it, which is the GOV.UK pattern and the reason a summary is worth having.
  #
  # Eighteen forms used to render a flash *as well*, so one failure produced two `role="alert"`
  # regions -- announced twice, and disagreeing about what to say. The summary said "Storage
  # location must exist"; the flash said "storage_location: must exist" on /adjustments and
  # "Something didn't work quite right -- try again?" on eight others, which is not information.
  #
  # The flash is still right when there is nothing to summarise. A service can raise without
  # putting anything on the record, and `essentials_error_summary` renders nothing for a record
  # with no errors -- so without this guard the page would come back with no sign of trouble at
  # all. Operational failure gets the flash; validation failure gets the summary; never both.
  def flash_error_unless_summarised(record, message)
    flash.now[:error] = message if record.nil? || record.errors.empty?
  end

  def not_found!
    respond_to do |format|
      format.html { render template: "errors/404", layout: "layouts/essentials_app", status: :not_found }
      format.json { render body: nil, status: :not_found }
    end
  end

  def verboten!
    respond_to do |format|
      format.html { redirect_to dashboard_path_from_current_role, flash: { error: "Access Denied." } }
      format.json { render body: nil, status: :forbidden }
    end
  end

  def omgwtfbbq!
    respond_to do |format|
      # "layouts/error" has never existed -- this raised a missing-template error on top of
      # whatever caused the 500 in the first place.
      format.html { render template: "errors/500", layout: "layouts/essentials_app", status: :internal_server_error }
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

  def handle_csv_export
    return unless params[:export_csv]

    # The flag starts the background fetch; the notice is the part a person reads, and it goes
    # through the flash strip like every other message. main paired the flag with a `toastr` call
    # instead -- see shared/essentials/_csv_download for why that could not come across.
    flash[:trigger_csv_download] = true
    flash[:notice] = "Your CSV export is downloading."
    clean_params = request.query_parameters.except("export_csv")
    redirect_url = clean_params.any? ? "#{request.path}?#{clean_params.to_query}" : request.path
    redirect_to redirect_url
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:account_update, keys: [:name])
  end
end
