module Exports
  class ExportDistributionsCSVService
    def initialize(distributions:, filters: [])
      # Currently, the @distributions are already loaded by the controllers that are delegating exporting
      # to this service object; this is happening within the same request/response cycle, so it's already
      # in memory, so we can pass that collection in directly. Should this be moved to a background / async
      # job, we will need to pass in a collection of IDs instead.
      # Also, adding in a `filters` parameter to make the filters that have been used available to this
      # service object.
      @distributions = distributions
      @filters = filters
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
      distributions.each do |distribution|
        csv_data << build_row_data(distribution)
      end

      csv_data
    end

    private

    attr_reader :distributions

    def headers
      # Build the headers in the correct order
      base_headers + item_headers
    end

    # Returns a Hash of keys to indexes so that obtaining the index
    # doesn't require a linear scan.
    def headers_with_indexes
      @headers_with_indexes ||= headers.each_with_index.to_h
    end

    # This method keeps the base headers associated with the lambdas
    # for extracting the values for the base columns from the given
    # distribution.
    #
    # Doing so (as opposed to expressing them in distinct methods) makes
    # it less likely that a future edit will inadvertently modify the
    # order of the headers in a way that isn't also reflected in the
    # values for the these base columns.
    #
    # Reminder: Since Ruby 1.9, Hashes are ordered based on insertion
    # (or on the order of the literal).
    def base_table
      {
        "Partner" => ->(distribution) {
          distribution.partner.name
        },
        "Date of Distribution" => ->(distribution) {
          distribution.issued_at.strftime("%m/%d/%Y")
        },
        "Source Inventory" => ->(distribution) {
          distribution.storage_location.name
        },
        base_item_header_col_name => ->(distribution) {
          # filter the line items by item id (for selected item filter) to
          # get the number of items
          if @filters[:by_item_id].present?
            distribution.line_items.where(item_id: @filters[:by_item_id].to_i).total
          else
            distribution.line_items.total
          end
        },
        "Total Value" => ->(distribution) {
          distribution.cents_to_dollar(distribution.line_items.total_value)
        },
        "Delivery Method" => ->(distribution) {
          distribution.delivery_method
        },
        "State" => ->(distribution) {
          distribution.state
        },
        "Agency Representative" => ->(distribution) {
          distribution.agency_rep
        },
        "Comments" => ->(distribution) {
          distribution.comment
        }
      }
    end

    # if filtered based on an item, change the column accordingly
    def base_item_header_col_name
      @filters[:by_item_id].present? ? "Total Number of #{filtered_item.name}" : "Total Items"
    end

    def filtered_item
      @filtered_item ||= Item.find(@filters[:by_item_id].to_i)
    end

    def base_headers
      base_table.keys
    end

    def item_headers
      # Define the item_headers by taking each item name
      # and sort them alphabetically
      item_names = distributions.map do |distribution|
        distribution.line_items.map(&:item).map(&:name)
      end.flatten

      item_names.sort.uniq
    end

    def build_row_data(distribution)
      row = base_table.values.map { |closure| closure.call(distribution) }

      row += Array.new(item_headers.size, 0)

      distribution.line_items.each do |line_item|
        item_name = line_item.item.name
        item_column_idx = headers_with_indexes[item_name]
        row[item_column_idx] += line_item.quantity
      end

      row
    end
  end
end
