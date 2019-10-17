class AddReminderEmailEnabledToDistributions < ActiveRecord::Migration[5.2]
  def change
    add_column :distributions, :reminder_email_enabled, :boolean, null: false, default: false
  end
end
