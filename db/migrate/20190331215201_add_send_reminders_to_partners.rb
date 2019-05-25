# Indicate that an organization would like to automatically send reminders to partners
class AddSendRemindersToPartners < ActiveRecord::Migration[5.2]
  def change
    add_column :partners, :send_reminders, :boolean, null: false, default: false
  end
end
