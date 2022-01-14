class ValidateAddReminderDayOfMonthAndDeadlineDayOfMonth < ActiveRecord::Migration[6.1]
  def change
    validate_check_constraint :partner_groups, name: "deadline_day_of_month_check"
    validate_check_constraint :partner_groups, name: "reminder_day_of_month_check"
    validate_check_constraint :partner_groups, name: "reminder_day_of_month_and_deadline_day_of_month_check"
  end
end
