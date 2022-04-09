class ReinstateDeadlineCheckConstraintsOnpartnerGroups < ActiveRecord::Migration[6.1]
  def change
    add_check_constraint :partner_groups, "deadline_day <= 28", name: "deadline_day_of_month_check", validate: false
    add_check_constraint :partner_groups, "reminder_day <= 28", name: "reminder_day_of_month_check", validate: false
  end end
