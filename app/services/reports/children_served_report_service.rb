module Reports
  class ChildrenServedReportService
    attr_reader :year, :organization

    def initialize(year:, organization:)
      @year = year
      @organization = organization
    end

    def report
      @report ||= {
        children_served_by_partner: children_served_by_partner.to_s,
        monthly_children_served: monthly_children_served
      }
    end

    def columns_for_csv
      %i[children_served_by_partner monthly_children_served]
    end

    def children_served_by_partner
      organization.partners.map do |partner|
        partner.profile.children.count
      end.sum
    end

    def monthly_children_served
      (children_served_by_partner / 12).to_s
    end
  end
end