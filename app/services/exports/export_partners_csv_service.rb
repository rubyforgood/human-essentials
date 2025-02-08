module Exports
  class ExportPartnersCSVService
    # Currently, the @partners are already loaded by the controllers that are delegating exporting
    # to this service object; this is happening within the same request/response cycle, so it's already
    # in memory, so we can pass that collection in directly. Should this be moved to a background / async
    # job, we will need to pass in a collection of IDs instead.
    def initialize(partners)
      @partners = partners.includes(:profile)
    end

    def generate_csv
      csv_data = generate_csv_data

      CSV.generate(headers: true) do |csv|
        csv_data.each { |row| csv << row }
      end
    end

    def generate_csv_data
      csv_data = []

      csv_data << headers
      @partners.each do |partner|
        csv_data << build_row_data(partner)
      end

      csv_data
    end

    private

    attr_reader :partners

    def headers
      base_table.keys
    end

    def base_table
      {
        "Agency Name" => ->(partner) { partner.name },
        "Agency Email" => ->(partner) { partner.email },
        "Agency Address" => ->(partner) { partner.agency_info[:address] },
        "Agency City" => ->(partner) { partner.agency_info[:city] },
        "Agency State" => ->(partner) { partner.agency_info[:state] },
        "Agency Zip Code" => ->(partner) { partner.agency_info[:zip_code] },
        "Agency Website" => ->(partner) { partner.agency_info[:website] },
        "Agency Type" => ->(partner) { partner.agency_info[:agency_type] },
        "Contact Name" => ->(partner) { partner.contact_person[:name] },
        "Contact Phone" => ->(partner) { partner.contact_person[:phone] },
        "Contact Email" => ->(partner) { partner.contact_person[:email] },
        "Notes" => ->(partner) { partner.notes },
        "Counties Served" => fetch_county_list_by_region,
        "Providing Diapers" => fetch_diaper_status,
        "Providing Period Supplies" => fetch_period_supplies_status
      }
    end

    def build_row_data(partner)
      base_table.values.map { |closure| closure.call(partner) }
    end

    def fetch_county_list_by_region
      ->(partner) { partner_county_list_by_regions[partner.id] || "" }
    end

    def fetch_diaper_status
      ->(partner) { partner_diaper_statuses[partner.id] }
    end

    def fetch_period_supplies_status
      ->(partner) { partner_period_supplies_statuses[partner.id] }
    end

    # Returns a hash with partner ids as keys and served county names
    # joined by semi-colons as values.
    #
    # @return [Hash<Integer, String>]
    def partner_county_list_by_regions
      return @partner_county_list_by_regions if @partner_county_list_by_regions

      # To prevent SQL injection in case users gain the ability to update county name/regions
      county_name = ActiveRecord::Base.connection.quote_string("counties.name")
      county_region = ActiveRecord::Base.connection.quote_string("counties.region")

      @partner_county_list_by_regions =
        partners
          .joins(profile: :counties)
          .group(:id)
          .pluck(Arel.sql("partners.id, STRING_AGG(#{county_name}, '; ' ORDER BY #{county_region}, #{county_name}) AS county_list"))
          .to_h
    end

    # Returns a hash with partner ids as keys with "Y" 's as values
    # The hash has a default value of "N" so partner ids not in hash will return "N"
    #
    # @return [Hash<Integer, String>]
    def partner_diaper_statuses
      return @partner_diaper_statuses if @partner_diaper_statuses

      @partner_diaper_statuses = Hash.new("N")
      partners.unscope(:order).joins(:distributions).merge(Distribution.in_last_12_months.with_diapers).distinct.ids.each do |id|
        @partner_diaper_statuses[id] = "Y"
      end
      @partner_diaper_statuses
    end

    # Returns a hash with partner ids as keys with "Y" 's as values
    # The hash has a default value of "N" so partner ids not in hash will return "N"
    #
    # @return [Hash<Integer, String>]
    def partner_period_supplies_statuses
      return @partner_period_supplies_statuses if @partner_period_supplies_statuses

      @partner_period_supplies_statuses = Hash.new("N")
      partners.unscope(:order).joins(:distributions).merge(Distribution.in_last_12_months.with_period_supplies).distinct.ids.each do |id|
        @partner_period_supplies_statuses[id] = "Y"
      end
      @partner_period_supplies_statuses
    end
  end
end
