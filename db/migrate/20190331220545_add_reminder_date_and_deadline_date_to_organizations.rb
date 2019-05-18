# Organizations can remind Partners when their deadlines are for putting in their requests
class AddReminderDateAndDeadlineDateToOrganizations < ActiveRecord::Migration[5.2]
  def change
    add_column :organizations, :reminder_days_before_deadline, :integer
    add_column :organizations, :deadline_date, :integer
  end
end
