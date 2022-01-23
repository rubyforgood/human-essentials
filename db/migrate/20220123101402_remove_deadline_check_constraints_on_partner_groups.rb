class RemoveDeadlineCheckConstraintsOnPartnerGroups < ActiveRecord::Migration[6.1]
  def change
    remove_check_constraint :partner_groups, "deadline_day_of_month <= 28", name: "deadline_day_of_month_check", validate: false
    remove_check_constraint :partner_groups, "reminder_day_of_month <= 14", name: "reminder_day_of_month_check", validate: false
    remove_check_constraint :partner_groups, "deadline_day_of_month > reminder_day_of_month", name: "reminder_day_of_month_and_deadline_day_of_month_check", validate: false
  end
end
