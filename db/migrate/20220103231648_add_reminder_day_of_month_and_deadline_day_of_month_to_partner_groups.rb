class AddReminderDayOfMonthAndDeadlineDayOfMonthToPartnerGroups < ActiveRecord::Migration[6.1]
  def change
    add_column :partner_groups, :send_reminders, :boolean,  null: false
    add_column :partner_groups, :reminder_day_of_month, :integer
    add_column :partner_groups, :deadline_day_of_month, :integer
    change_column_default :partner_groups, :send_reminders, from: nil, to: false
    add_check_constraint :partner_groups, "deadline_day_of_month <= 28", name: "deadline_day_of_month_check", validate: false
    add_check_constraint :partner_groups, "reminder_day_of_month <= 14", name: "reminder_day_of_month_check", validate: false
    add_check_constraint :partner_groups, "deadline_day_of_month > reminder_day_of_month", name: "reminder_day_of_month_and_deadline_day_of_month_check", validate: false
  end
end
