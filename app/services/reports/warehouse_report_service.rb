module Reports
  class WarehouseReportService
    attr_reader :year, :organization

    # @param year [Integer]
    # @param organization [Organization]
    def initialize(year:, organization:)
      @year = year
      @organization = organization
    end

    def report
      @report ||= { name: 'Warehouse and Storage',
                    entries: {
                      'Total storage locations' => storage_location_count,
                      'Total square footage' => total_square_footage,
                      'Largest storage site type' => largest_storage_location_type
                    } }
    end

    # @return [Integer]
    def storage_location_count
      @organization.storage_locations.count
    end

    # @return [String]
    def total_square_footage
      ret = @organization.storage_locations.sum(:square_footage).to_s
      no_square_footage = @organization.storage_locations.where(square_footage: nil).count
      if no_square_footage.positive?
        ret += " (#{no_square_footage} locations do not have square footage entered)"
      end
      ret
    end

    # @return [String]
    def largest_storage_location_type
      max = @organization.storage_locations
                         .order(square_footage: :desc)
                         .where.not(square_footage: nil)
                         .first
      if max.nil?
        "No warehouses with square footage entered"
      else
        max.warehouse_type || "#{max.name} - warehouse type not given"
      end
    end
  end
end
