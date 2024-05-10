# [Organization Admin] Audits are for OrgAdmins to reconcile their real-world counts with their digital counts.
class AuditsController < ApplicationController
  before_action :authorize_admin
  before_action :set_audit, only: %i(show edit update destroy finalize)

  def index
    @selected_location = filter_params[:at_location]
    @audits = current_organization.audits.class_filter(filter_params)
    @storage_locations = Audit.storage_locations_audited_for(current_organization).uniq
  end

  def show
    if Event.read_events?(@audit.organization)
      @items = View::Inventory.items_for_location(@audit.storage_location)
    else
    end
  end

  def edit
    (redirect_to audits_path unless @audit&.in_progress?) && return
    @storage_locations = [@audit.storage_location]
    set_items
    @audit.line_items.build if @audit.line_items.empty?
  end

  def finalize
    @audit.adjustment = Adjustment.new(organization_id: @audit.organization_id, storage_location_id: @audit.storage_location_id, user_id: current_user.id, comment: 'Created Automatically through the Auditing Process')
    @audit.save

    AuditEvent.publish(@audit)
    @audit.finalized!
    redirect_to audit_path(@audit), notice: "Audit is Finalized."
  rescue => e
    redirect_back(fallback_location: audits_path, alert: "Could not finalize audit: #{e.message}")
  end

  def update
    @audit.line_items.destroy_all
    if @audit.update(audit_params)
      save_audit_status_and_redirect(params)
    else
      flash[:error] = @audit.errors.full_messages.join("\n")
      @storage_locations = [@audit.storage_location]
      set_items
      @audit.line_items.build if @audit.line_items.empty?
      render action: :edit
    end
  end

  def new
    @audit = current_organization.audits.new
    @audit.line_items.build
    set_storage_locations
    set_items
  end

  def create
    @audit = current_organization.audits.new(audit_params)
    @audit.user = current_user
    if @audit.save
      save_audit_status_and_redirect(params)
    else
      handle_audit_errors
      set_storage_locations
      set_items
      @audit.line_items.build if @audit.line_items.empty?
      render :new
    end
  rescue Errors::InsufficientAllotment, InventoryError => e
    flash[:error] = e.message
    render :new
  end

  def destroy
    (redirect_to audits_path if @audit.finalized?) && return
    @audit.destroy!
    redirect_to audits_path, notice: "Audit is successfully deleted."
  end

  private

  def handle_audit_errors
    error_message = @audit.errors.uniq(&:attribute).map do |error|
      attr = (error.attribute.to_s == 'base') ? '' : error.attribute.capitalize
      "#{attr} ".tr("_", " ") + error.message
    end
    flash[:error] = error_message.join(", ")
  end

  def set_audit
    @audit = current_organization.audits.find(params[:id] || params[:audit_id])
  end

  def set_storage_locations
    @storage_locations = current_organization.storage_locations.active_locations
  end

  def set_items
    @items = current_organization.items.alphabetized
  end

  def save_audit_status_and_redirect(params)
    notice = params.key?(:save_progress) ? "Audit's progress was successfully saved." : "Audit is confirmed."
    params.key?(:save_progress) ? @audit.in_progress! : @audit.confirmed!
    redirect_to audit_path(@audit), notice: notice
  end

  def audit_params
    params.require(:audit).permit(:organization_id, :storage_location_id,
                                  line_items_attributes: %i(item_id quantity _destroy))
  end

  def filter_params
    return {} unless params.key?(:filters)

    params.require(:filters).slice(:at_location)
  end
end
