module Exports
  class ExportRequestService
    DELETED_ITEMS_COLUMN_HEADER = '<DELETED_ITEMS>'.freeze

    def initialize(requests)
      @requests = requests.includes(:partner)
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
      item_names = items.pluck(:name)

      # Adding this to handle cases in which a requested item
      # has been deleted. Normally this wouldn't be neccessary,
      # but previous versions of the application would cause
      # this orphaned data
      item_names.sort.uniq << DELETED_ITEMS_COLUMN_HEADER
    end

    def build_row_data(request)
      row = base_table.values.map { |closure| closure.call(request) }

      row += Array.new(item_headers.size, 0)

      request.request_items.each do |request_item|
        item_name = fetch_item_name(request_item['item_id']) || DELETED_ITEMS_COLUMN_HEADER
        item_column_idx = headers_with_indexes[item_name]

        if item_name == DELETED_ITEMS_COLUMN_HEADER
          # Add to the deleted column for every item that
          # does not match any existing Item.
          row[item_column_idx] ||= 0
        end
        row[item_column_idx] += request_item['quantity']
      end

      row
    end

    def fetch_item_name(item_id)
      @item_name_to_id_map ||= items.inject({}) do |acc, item|
        acc[item.id] = item.name
        acc
      end

      @item_name_to_id_map[item_id]
    end

    def items
      return @items if @items

      item_ids = requests.flat_map do |request|
        request.request_items.map { |item| item['item_id'] }
      end

      @items ||= Item.where(id: item_ids)
    end
  end
end
