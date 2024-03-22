class AddEmailNotificationOptInToOrganizations < ActiveRecord::Migration[7.0]
  def change
    add_column :organizations, :email_notification_opt_in, null: false, default: false
  end
end
