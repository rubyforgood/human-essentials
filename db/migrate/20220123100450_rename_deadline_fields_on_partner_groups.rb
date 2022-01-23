class RenameDeadlineFieldsOnPartnerGroups < ActiveRecord::Migration[6.1]
  def change
    safety_assured do
      # Strong migrations complains that we should to this in multiple steps (new col, backfill, switch reads, delete old)
      # I think it's fine as small scale.
      rename_column :partner_groups, :deadline_day_of_month, :deadline_day
      rename_column :partner_groups, :reminder_day_of_month, :reminder_day
    end
  end
end
