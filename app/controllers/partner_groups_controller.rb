class PartnerGroupsController < ApplicationController
  # Migrated to the Ruby for Good design system (ADR 0011).
  layout "essentials_app"

  before_action :set_partner_group, only: %i[edit destroy]

  def index
    @partner_groups = current_organization.partner_groups.includes(:partners, :item_categories)
  end

  def new
    @partner_group = current_organization.partner_groups.new
    set_items_categories
    @item_categories = current_organization.item_categories
  end

  def create
    @partner_group = current_organization.partner_groups.new(partner_group_params)
    @partner_group.reminder_schedule.assign_attributes(reminder_schedule_params)
    if @partner_group.save
      # Redirect to groups tab in Partner page.
      redirect_to partners_path + "#nav-partner-groups", notice: "Partner group added!"
    else
      flash_error_unless_summarised(@partner_group, "Something didn't work quite right -- try again?")
      set_items_categories
      render action: :new
    end
  end

  def edit
    @partner_group = current_organization.partner_groups.find(params[:id])
    set_items_categories
    @item_categories = current_organization.item_categories
  end

  def update
    @partner_group = current_organization.partner_groups.find(params[:id])
    @partner_group.reminder_schedule.assign_attributes(reminder_schedule_params)
    if @partner_group.update(partner_group_params)
      redirect_to partners_path + "#nav-partner-groups", notice: "Partner group edited!"
    else
      flash_error_unless_summarised(@partner_group, "Something didn't work quite right -- try again?")
      set_items_categories
      render action: :edit
    end
  end

  def destroy
    if @partner_group.partners.any?
      # The old message said only that it could not be deleted, and pointed at a `#nav-partner-groups`
      # anchor from when the groups list was a tab rather than its own page.
      redirect_to partner_groups_path,
        alert: "#{@partner_group.name} still has partners, so it cannot be deleted. " \
               "Move them to another group or remove them from this one, then delete it."
    else
      @partner_group.destroy
      respond_to do |format|
        format.html { redirect_to partners_path + "#nav-partner-groups", notice: "Partner Group was successfully deleted." }
      end
    end
  end

  private

  def set_partner_group
    @partner_group = current_organization.partner_groups.find(params[:id])
  end

  def partner_group_params
    params.require(:partner_group).permit(:name, :send_reminders, :reminder_schedule_definition, :deadline_day, item_category_ids: [])
  end

  def reminder_schedule_params
    params.require(:partner_group).fetch(:reminder_schedule_service, {}).permit([*ReminderScheduleService::REMINDER_SCHEDULE_FIELDS])
  end

  def set_items_categories
    @item_categories = current_organization.item_categories
  end
end
