# [Organization Admin] Audits are for OrgAdmins to reconcile their real-world counts with their digital counts.
class AuditsController < ApplicationController
  # Migrated to the Ruby for Good design system (ADR 0011).
  layout "essentials_app"

  before_action :authorize_admin
  before_action :set_audit, only: %i(show edit update destroy finalize)
  before_action :ensure_audit_is_editable, only: %i(finalize update)

  def index
    @selected_location = filter_params[:at_location]
    @audits = current_organization.audits.includes(:line_items, :storage_location).class_filter(filter_params)
    @storage_locations = StorageLocation.with_audits_for(current_organization).select(:id, :name)
    # The CSV export below wants every row; the table wants one page of them.
    @paginated_audits = @audits.page(params[:page]).per(Pagination::COMPACT)

    respond_to do |format|
      format.html
      format.csv do
        send_data Audit.generate_csv(@audits), filename: "Audits-#{Time.zone.today}.csv"
      end
    end
  end

  def show
    @items = View::Inventory.items_for_location(@audit.storage_location, include_omitted: true)
  end

  def edit
    (redirect_to audits_path unless @audit&.in_progress?) && return
    @storage_locations = [@audit.storage_location]
    set_items
    @audit.line_items.build if @audit.line_items.empty?
  end

  def finalize
    AuditEvent.publish(@audit)
    @audit.finalized!
    redirect_to audit_path(@audit), notice: "Audit is Finalized."
  rescue => e
    redirect_back_or_to(audits_path, alert: "Could not finalize audit: #{e.message}")
  end

  def update
    @audit.line_items.destroy_all
    if @audit.update(audit_params)
      save_audit_status_and_redirect(params)
    else
      flash_error_unless_summarised(@audit, "This audit could not be saved.")
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
      # No handle_audit_errors here: @audit keeps its errors, so the summary above the form lists
      # them and each field carries its own. The flash was a third copy of the same sentence.
      set_storage_locations
      set_items
      @audit.line_items.build if @audit.line_items.empty?
      render :new
    end
  rescue Errors::InsufficientAllotment, InventoryError => e
    flash_error_unless_summarised(@audit, e.message)
    render :new
  end

  def destroy
    (redirect_to audits_path if @audit.finalized?) && return
    @audit.destroy!
    redirect_to audits_path, notice: "Audit is successfully deleted."
  end

  private

  # From main: a finalized audit cannot be edited. `error:` is a registered flash type
  # (add_flash_types in ApplicationController), so this renders through the flash strip.
  def ensure_audit_is_editable
    if @audit.reload.finalized?
      redirect_to audit_path(@audit), error: "This audit has been finalized and cannot be edited."
    end
  end

  # main's `handle_audit_errors` is deliberately not merged. It flattened the record's errors into
  # one flash sentence, and nothing calls it here any more: `update` keeps the errors on @audit so
  # the summary above the form lists them and each field carries its own. See the comment in
  # `update` -- the flash was a third copy of the same sentence.

  def set_audit
    @audit = current_organization.audits.find(params[:id] || params[:audit_id])
  end

  def set_storage_locations
    @storage_locations = current_organization.storage_locations.active
  end

  def set_items
    @items = current_organization.items.where(active: true).alphabetized
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
