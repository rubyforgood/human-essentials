class SeedReminderScheduleData < ActiveRecord::Migration[7.1]
  def change
    for o in Organization.all
      if o.reminder_day.present?
        reminder_schedule = o.convert_to_reminder_schedule(o.reminder_day)
        o.update(reminder_schedule: reminder_schedule)
      end
    end

    for pg in PartnerGroup.all
      if pg.reminder_day.present?
        reminder_schedule = pg.convert_to_reminder_schedule(pg.reminder_day)
        pg.update(reminder_schedule: reminder_schedule)
      end
    end
  end
end
