module Partners
  class FetchPartnersToRemindNowService
    def fetch
      current_day = Time.current.day
      deactivated_status = ::Partner.statuses[:deactivated]

      partners_with_group_reminders = ::Partner.left_joins(:partner_group)
        .where(partner_groups: {reminder_day: current_day})
        .where.not(partner_groups: {deadline_day: nil})
        .where.not(status: deactivated_status)

      partners_with_only_organization_reminders = ::Partner.left_joins(:partner_group, :organization)
        .where(partner_groups: {reminder_day: nil})
        .where(send_reminders: true)
        .where(organizations: {reminder_day: current_day})
        .where.not(organizations: {deadline_day: nil})
        .where.not(status: deactivated_status)

      (partners_with_group_reminders + partners_with_only_organization_reminders).flatten.uniq
    end
  end
end
