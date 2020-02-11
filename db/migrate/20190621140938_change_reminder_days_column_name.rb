class ChangeReminderDaysColumnName < ActiveRecord::Migration[5.2]
  def up
    rename_column :organizations, :reminder_days_before_deadline, :reminder_day
    rename_column :organizations, :deadline_date, :deadline_day
  end

  def down
    rename_column :organizations, :reminder_day, :reminder_days_before_day
    rename_column :organizations, :deadline_day, :deadline_date
  end
end
