class SeedReminderScheduleData < ActiveRecord::Migration[7.1]
  def change
    for o in Organization.all
      if o.reminder_day.present?
        reminder_schedule = ReminderScheduleService.new({every_nth_month: "1", by_month_or_week: "day_of_month", day_of_month: o.reminder_day})
        o.update_column(:reminder_schedule_definition, reminder_schedule.to_ical)
      end
    end

    for pg in PartnerGroup.all
      if pg.reminder_day.present?
        reminder_schedule = ReminderScheduleService.new({every_nth_month: "1", by_month_or_week: "day_of_month", day_of_month: pg.reminder_day})
        pg.update_column(:reminder_schedule_definition, reminder_schedule.to_ical)
      end
    end
  end
end
