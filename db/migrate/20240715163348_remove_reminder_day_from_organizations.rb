class RemoveReminderDayFromOrganizations < ActiveRecord::Migration[7.1]
  def change
    safety_assured { remove_column :organizations, :reminder_day }
    safety_assured { remove_column :partner_groups, :reminder_day }
  end
end
