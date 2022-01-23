class UpdateInvalidReminderDaysOnOrganizations < ActiveRecord::Migration[6.1]
  def up
    # Finds any organizations where deadline_day = reminder_day and sets reminder day to the day before
    # deadline day. If deadline day is 1, wraps reminder day around to 28.
    safety_assured do
      execute <<~SQL
        UPDATE organizations
        SET reminder_day = (CASE
        WHEN deadline_day = 1 THEN 28
        ELSE deadline_day - 1
        END)
          WHERE deadline_day IS NOT NULL
          AND reminder_day IS NOT NULL
          AND deadline_day = reminder_day;
      SQL
    end
  end
end
