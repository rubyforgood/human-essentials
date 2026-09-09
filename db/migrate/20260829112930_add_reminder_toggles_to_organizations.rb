class AddReminderTogglesToOrganizations < ActiveRecord::Migration[8.1]
  def up
    add_column :organizations, :deadline_reminders_enabled, :boolean, null: false, default: false
    add_column :organizations, :distribution_reminders_enabled, :boolean, null: false, default: false

    # Set the existing orgs value to true.
    # This preserves current behavior since emails only get sent if the org already has reminder settings.
    Organization.update_all(deadline_reminders_enabled: true, distribution_reminders_enabled: true)
  end

  def down
    remove_column :organizations, :distribution_reminders_enabled
    remove_column :organizations, :deadline_reminders_enabled
  end
end
