module Reports
  class WarehouseInfoReportService
    def initialize(year:, organization:)
      @year = year
      @organization = organization
    end

    def report
      @report ||= {
        storage_locations_count: storage_locations.count,
        square_footage: storage_locations.pluck(:square_footage).sum.to_s,
        largest_location: storage_locations.order(square_footage: :desc).first.name
      }
    end

    def columns_for_csv
      %i[storage_locations_count square_footage largest_location]
    end

    attr_reader :year, :organization
    delegate :storage_locations, to: :organization

    def square_footage
      storage_locations.pluck(:square_footage).sum.to_s
    end

    def largest_location
      storage_locations.order(square_footage: :desc).first.name
    end
  end
end
