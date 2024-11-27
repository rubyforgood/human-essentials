module Reports
  class PartnerInfoReportService
    include ActionView::Helpers::NumberHelper
    attr_reader :year, :organization

    # @param year [Integer]
    # @param organization [Organization]
    def initialize(year:, organization:)
      @year = year
      @organization = organization
    end

    # @return [Hash]
    def report
      return @report if @report

      entries = { 'Number of Partner Agencies' => partner_agencies }
      partner_agency_counts.each do |agency, count|
        entries["Agency Type: #{agency || 'Unknown'}"] = count
      end
      entries['Zip Codes Served'] = partner_zipcodes_serviced
      @report = { name: 'Partner Agencies and Service Area', entries: entries }
    end

    # @return [Array<Partner>]
    def partner_agency_profiles
      @partner_agency_profiles ||= organization.partners.map(&:profile).compact
    end

    # @return [Integer]
    def partner_agencies
      partner_agency_profiles.size
    end

    def partner_agency_counts
      partner_agency_profiles.map(&:agency_type).tally
    end

    def partner_zipcodes_serviced
      partner_agency_profiles.map(&:zips_served).uniq.sort.join(', ')
    end
  end
end
