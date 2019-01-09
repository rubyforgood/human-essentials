class AuditsController < ApplicationController
  def index
    # @selected_location = filter_params[:at_location]
    # @audit_adjustments = current_organization.adjustments.where(id: current_organization.audits.pluck(:adjustment_id))
    # @storage_locations = Adjustment.storage_locations_adjusted_for(current_organization).uniq
  end

  def new
    @audit = current_organization.audits.new
    @audit.build_adjustment.line_items.build
    @storage_locations = current_organization.storage_locations
    @items = current_organization.items.alphabetized
  end

  def create
    @audit = current_organization.audits.new(audit_params)
    @audit.user_id = current_user.id
    @audit.adjustment.organization_id = @audit.organization_id
    if @audit.valid?
      if @audit.save
        @audit.confirmed!
        redirect_to audits_path(@audit), notice: "Audit was successfully created."
      else
        flash[:error] = @audit.errors.collect { |model, message| "#{model}: " + message }.join("<br />".html_safe)
        render :new
      end
    else
      flash[:error] = @audit.errors.collect { |model, message| "#{model}: " + message }.join("<br />".html_safe)
      render :new
    end
  end

  private

  def audit_params
    params.require(:audit).permit(:organization_id,
                                  adjustment_attributes: [:organization_id, :storage_location_id,
                                                          line_items_attributes: %i(item_id quantity _destroy)])
  end

  # def filter_params
  #   return {} unless params.key?(:filters)
  #
  #   params.require(:filters).slice(:at_location)
  # end
end
