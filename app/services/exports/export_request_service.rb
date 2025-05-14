module Exports
  class ExportRequestService
    DELETED_ITEMS_COLUMN_HEADER = '<DELETED_ITEMS>'.freeze

    # @param requests [Array<Request>]
    # @param organization [Organization]
    def initialize(requests, organization)
      @requests = requests.includes(:partner, {item_requests: :item})
      @organization = organization
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
      requests.each do |request|
        csv_data << build_row_data(request)
      end

      csv_data
    end

    private

    attr_reader :requests

    def headers
      # Build the headers in the correct order
      base_headers + item_headers
    end

    def headers_with_indexes
      @headers_with_indexes ||= headers.each_with_index.to_h
    end

    def base_table
      {
        "Date" => ->(request) {
          request.created_at.strftime("%m/%d/%Y")
        },
        "Requestor" => ->(request) {
          request.partner.name
        },
        "Type" => ->(request) {
          request.request_type&.humanize
        },
        "Status" => ->(request) {
          request.status.humanize
        }
      }
    end

    def base_headers
      base_table.keys
    end

    def item_headers
      @item_headers ||= compute_item_headers
    end

    def compute_item_headers
      # This reaches into the item, handling invalid deleted items
      item_names = Set.new
      all_item_requests.each do |item_request|
        if item_request.item
          item = item_request.item
          item_names << item.name
          if Flipper.enabled?(:enable_packs)
            item.request_units.each do |unit|
              item_names << "#{item.name} - #{unit.name.pluralize}"
            end

            # It's possible that the unit is no longer valid, so we'd
            # add that individually
            if item_request.request_unit.present?
              item_names << "#{item.name} - #{item_request.request_unit.pluralize}"
            end
          end
        end
      end

      # Adding this to handle cases in which a requested item
      # has been deleted. Normally this wouldn't be necessary,
      # but previous versions of the application would cause
      # this orphaned data
      item_names.sort.uniq << DELETED_ITEMS_COLUMN_HEADER
    end

    def build_row_data(request)
      row = base_table.values.map { |closure| closure.call(request) }

      row += Array.new(item_headers.size, 0)

      request.item_requests.each do |item_request|
        item_name = item_request.item.present? ? item_request.name_with_unit(0) : DELETED_ITEMS_COLUMN_HEADER
        item_column_idx = headers_with_indexes[item_name]
        row[item_column_idx] ||= 0
        row[item_column_idx] += item_request.quantity.to_i
      end

      row
    end

    def all_item_requests
      @all_item_requests ||= Partners::ItemRequest.where(request: requests).includes(item: :request_units)
    end
  end
end
