class AuditsController < ApplicationController
  before_action :set_audit, only: %i(show edit update destroy finalize)

  def index
    @selected_location = filter_params[:at_location]
    @audits = current_organization.audits.filter(filter_params)
    @storage_locations = Audit.storage_locations_audited_for(current_organization).uniq
  end

  def show; end

  def edit
    (redirect_to audits_path unless @audit&.in_progress?) && return
    @storage_locations = current_organization.storage_locations
    @items = current_organization.items.alphabetized
    @audit.line_items.build if @audit.line_items.empty?
  end

  def finalize
    @audit.finalized!
    redirect_to audit_path(@audit), notice: "Audit is Finalized"
  end

  def update
    @audit.line_items.destroy_all
    if @audit.update(audit_params)
      notice = params.key?(:save_progress) ? "Audit's progress was successfully saved." : "Audit is confirmed."
      params.key?(:save_progress) ? @audit.in_progress! : @audit.confirmed!
      redirect_to audit_path(@audit), notice: notice
    else
      flash[:error] = "Something didn't work quite right -- try again?"
      @audit.line_items.build if @audit.line_items.empty?
      render action: :edit
    end
  end

  def new
    @audit = current_organization.audits.new
    @audit.line_items.build
    @storage_locations = current_organization.storage_locations
    @items = current_organization.items.alphabetized
  end

  def create
    @audit = current_organization.audits.new(audit_params)
    @audit.user_id = current_user.id
    @storage_locations = current_organization.storage_locations
    @items = current_organization.items.alphabetized
    if @audit.valid?
      if @audit.save
        notice = params.key?(:save_progress) ? "Audit's progress was successfully saved." : "Audit is confirmed."
        params.key?(:save_progress) ? @audit.in_progress! : @audit.confirmed!
        redirect_to audit_path(@audit), notice: notice
      else
        flash[:error] = @audit.errors.collect { |model, message| "#{model}: " + message }
        @audit.line_items.build if @audit.line_items.empty?
        render :new
      end
    else
      flash[:error] = @audit.errors.collect { |model, message| "#{model}: " + message }
      @audit.line_items.build if @audit.line_items.empty?
      render :new
    end
  rescue Errors::InsufficientAllotment => ex
    flash[:error] = ex.message
    render :new
  end

  def destroy
    @audit.destroy!
    redirect_to audits_path
  end

  private

  def set_audit
    @audit = current_organization.audits.find(params[:id] || params[:audit_id])
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
