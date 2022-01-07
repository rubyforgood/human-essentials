module Partners
  class FetchPartnersToRemindNowService

    def initialize
    end

    def fetch
      current_day = Time.current.day

      partners_with_group_reminders = ::Partner.left_joins(:partner_group)
        .where(partner_groups: { reminder_day_of_month: current_day })
        .where.not(partner_groups: { deadline_day_of_month: nil })

      partners_with_only_organization_reminders = ::Partner.left_joins(:partner_group, :organization)
        .where(partner_groups: { reminder_day_of_month: nil })
        .where(send_reminders: true)
        .where(organizations: { reminder_day: current_day })
        .where.not(organizations: { deadline_day: nil })

      partners = (partners_with_group_reminders + partners_with_only_organization_reminders).flatten.uniq
      partners.reject(&:deactivated?)
    end

  end
end
