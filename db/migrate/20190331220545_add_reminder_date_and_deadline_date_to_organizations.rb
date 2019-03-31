class AddReminderDateAndDeadlineDateToOrganizations < ActiveRecord::Migration[5.2]
  def change
    add_column :organizations, :reminder_date, :integer
    add_column :organizations, :deadline_date, :integer
  end
end
