class AddReminderScheduleToOrganizations < ActiveRecord::Migration[7.1]
  def change
    add_column :organizations, :reminder_schedule, :string
    add_column :partner_groups, :reminder_schedule, :string
  end
end
