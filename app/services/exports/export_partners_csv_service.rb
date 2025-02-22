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
      CSV.generate(headers: true) do |csv|
        csv << headers
        partners.each { |partner| csv << build_row_data(partner) }
      end
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
        "Counties Served" => ->(partner) { county_list_by_regions[partner.id] || "" },
        "Providing Diapers" => ->(partner) { diaper_statuses[partner.id] },
        "Providing Period Supplies" => ->(partner) { period_supplies_statuses[partner.id] }
      }
    end

    def build_row_data(partner)
      base_table.values.map { |closure| closure.call(partner) }.map(&normalize_csv_attribute)
    end

    def normalize_csv_attribute
      ->(attr) { attr.is_a?(Array) ? attr.join(",") : attr.to_s }
    end

    # Returns a hash with partner ids as keys and served county names
    # joined by semi-colons as values.
    #
    # @return [Hash<Integer, String>]
    def county_list_by_regions
      return @county_list_by_regions if @county_list_by_regions

      @county_list_by_regions =
        partners
          .joins(profile: :counties)
          .group(:id)
          .pluck(Arel.sql("partners.id, STRING_AGG(counties.name, '; ' ORDER BY counties.region, counties.name) AS county_list"))
          .to_h
    end

    # Returns a hash with partner ids as keys with "Y" 's as values
    # The hash has a default value of "N" so partner ids not in hash will return "N"
    #
    # @return [Hash<Integer, String>]
    def diaper_statuses
      return @diaper_statuses if @diaper_statuses

      @diaper_statuses = Hash.new("N")
      partners.unscope(:order).joins(:distributions).merge(Distribution.in_last_12_months.with_diapers).distinct.ids.each do |id|
        @diaper_statuses[id] = "Y"
      end
      @diaper_statuses
    end

    # Returns a hash with partner ids as keys with "Y" 's as values
    # The hash has a default value of "N" so partner ids not in hash will return "N"
    #
    # @return [Hash<Integer, String>]
    def period_supplies_statuses
      return @period_supplies_statuses if @period_supplies_statuses

      @period_supplies_statuses = Hash.new("N")
      partners.unscope(:order).joins(:distributions).merge(Distribution.in_last_12_months.with_period_supplies).distinct.ids.each do |id|
        @period_supplies_statuses[id] = "Y"
      end
      @period_supplies_statuses
    end
  end
end
