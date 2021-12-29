module Reports
  class PartnerInfoReportService
    attr_reader :year, :organization
    delegate :partners, to: :organization
    delegate :count, to: :partners, prefix: true

    def initialize(year:, organization:)
      @year = year
      @organization = organization
    end

    def report
      @report ||= {
        partners_count: partners_count,
        partner_agency_type: partner_agency_type,
        partner_zipcodes_serviced: partner_zipcodes_serviced
      }
    end

    def columns_for_csv
      %i[partners_count partner_agency_type partner_zipcodes_serviced]
    end

    def partner_agency_type
      partners.map do |partner|
        partner.profile.agency_type
      end
    end

    def partner_zipcodes_serviced
      partners.map do |partner|
        partner.profile.zips_served
      end
    end
  end
end
