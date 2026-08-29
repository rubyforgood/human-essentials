class AddReminderTogglesToOrganizations < ActiveRecord::Migration[8.1]
  def up
    add_column :organizations, :deadline_reminders_enabled, :boolean, null: false, default: false
    add_column :organizations, :distribution_reminders_enabled, :boolean, null: false, default: false

    # Preserve current behavior for organizations that already have any reminder
    # configuration. New organizations opt in explicitly via their settings.
    configured_ids = Set.new
    configured_ids.merge Organization.where.not(reminder_schedule_definition: nil).ids
    configured_ids.merge Organization.where.not(deadline_day: nil).ids
    configured_ids.merge Organization.where.not(reminder_day: nil).ids
    configured_ids.merge Organization.joins(:partners).where(partners: {send_reminders: true}).distinct.ids
    configured_ids.merge Organization.joins(:partner_groups).where(partner_groups: {send_reminders: true}).distinct.ids
    configured_ids.merge Organization.joins(:distributions).where(distributions: {reminder_email_enabled: true}).distinct.ids

    Organization.where(id: configured_ids.to_a)
      .update_all(deadline_reminders_enabled: true, distribution_reminders_enabled: true)
  end

  def down
    remove_column :organizations, :distribution_reminders_enabled
    remove_column :organizations, :deadline_reminders_enabled
  end
end
