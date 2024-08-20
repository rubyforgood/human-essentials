class PartnerGroupsController < ApplicationController
  before_action :set_partner_group, only: %i[edit destroy]

  def new
    @partner_group = current_organization.partner_groups.new
    set_items_categories
  end

  def create
    @partner_group = current_organization.partner_groups.new(partner_group_params)
    if @partner_group.save
      # Redirect to groups tab in Partner page.
      redirect_to partners_path + "#nav-partner-groups", notice: "Partner group added!"
    else
      flash.now[:error] = "Something didn't work quite right -- try again?"
      set_items_categories
      render action: :new
    end
  end

  def edit
    @partner_group = current_organization.partner_groups.find(params[:id])
    set_items_categories
    @reminder_schedule = ReminderSchedule.from_ical(@partner_group.reminder_schedule)
    @item_categories = current_organization.item_categories
  end

  def update
    @partner_group = current_organization.partner_groups.find(params[:id])
    reminder_schedule = ReminderSchedule.new(reminder_schedule_params).create_schedule
    if @partner_group.update(partner_group_params.merge!(reminder_schedule:))
      redirect_to partners_path + "#nav-partner-groups", notice: "Partner group edited!"
    else
      flash.now[:error] = "Something didn't work quite right -- try again?"
      set_items_categories
      render action: :edit
    end
  end

  def destroy
    if @partner_group.partners.any?
      redirect_to partners_path + "#nav-partner-groups", alert: "Partner Group cannot be deleted."
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
    params.require(:partner_group).permit(:name, :send_reminders, :reminder_schedule, :deadline_day, item_category_ids: [])
  end

  def reminder_schedule_params
    params.require(:reminder_schedule).permit(:every_n_months, :date_or_week_day, :date, :day_of_week, :every_nth_day)
  end

  def set_items_categories
    @item_categories = current_organization.item_categories
  end
end
