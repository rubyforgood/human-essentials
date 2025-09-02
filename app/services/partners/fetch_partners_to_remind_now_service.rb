module Partners
  class FetchPartnersToRemindNowService
    def fetch
      current_day = Time.current
      deactivated_status = ::Partner.statuses[:deactivated]

      partners_with_group_reminders = ::Partner.left_joins(:partner_group)
        .where.not(partner_groups: {reminder_schedule_definition: nil})
        .where.not(partner_groups: {deadline_day: nil})
        .where.not(status: deactivated_status)

      # where partner groups have reminder schedule match
      filtered_partner_groups = partners_with_group_reminders.select do |partner|
        partner.partner_group.reminder_schedule.occurs_on?(current_day)
      end

      partners_with_only_organization_reminders = ::Partner.left_joins(:partner_group, :organization)
        .where(partner_groups: {reminder_schedule_definition: nil})
        .where(send_reminders: true)
        .where.not(organizations: {deadline_day: nil})
        .where.not(organizations: {reminder_schedule_definition: nil})
        .where.not(status: deactivated_status)

      filtered_organizations = partners_with_only_organization_reminders.select do |partner|
        partner.organization.reminder_schedule.occurs_on?(current_day)
      end
      (filtered_partner_groups + filtered_organizations).flatten.uniq
    end
  end
end
