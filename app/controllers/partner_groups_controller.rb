class PartnerGroupsController < ApplicationController
  def new
    @partner_group = current_organization.partner_groups.new
    @item_categories = current_organization.item_categories
  end

  def create
    @partner_group = current_organization.partner_groups.new(partner_group_params)
    if @partner_group.save
      # Redirect to groups tab in Partner page.
      redirect_to partners_path + "#nav-partner-groups", notice: "Partner group added!"
    else
      flash[:error] = "Something didn't work quite right -- try again?"
      render action: :new
    end
  end

  def edit
    @partner_group = current_organization.partner_groups.find(params[:id])
    @reminder_schedule = ReminderSchedule.from_ical(@partner_group.reminder_schedule)
    @item_categories = current_organization.item_categories
  end

  def update
    @partner_group = current_organization.partner_groups.find(params[:id])
    reminder_schedule = ReminderSchedule.new(reminder_schedule_params).create_schedule
    if @partner_group.update(partner_group_params.merge!(reminder_schedule:))
      redirect_to partners_path + "#nav-partner-groups", notice: "Partner group edited!"
    else
      flash[:error] = "Something didn't work quite right -- try again?"
      render action: :edit
    end
  end

  private

  def partner_group_params
    params.require(:partner_group).permit(:name, :send_reminders, :reminder_schedule, :deadline_day, item_category_ids: [])
  end

  def reminder_schedule_params
    params.require(:reminder_schedule).permit(:every_n_months, :date_or_week_day, :date, :day_of_week, :every_nth_day)
  end
end
