module Exports
  class ExportPurchasesCSVService
    def initialize(purchase_ids:)
      # Use a where lookup so that I can eager load all the resources
      # needed rather than depending on external code to do it for me.
      # This makes this code more self contained and efficient!
      @purchases = Purchase.includes(
        :storage_location,
        :vendor,
        line_items: [:item]
      ).where(
        id: purchase_ids
      ).order(created_at: :asc)
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
      purchases.each do |purchase|
        csv_data << build_row_data(purchase)
      end

      csv_data
    end

    private

    attr_reader :purchases

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
    # purchase.
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

        "Purchases from" => ->(purchase) {
          purchase.vendor.try(:business_name)
        },
        "Storage Location" => ->(purchase) {
          purchase.storage_view
        },
        "Purchased Date" => ->(purchase) {
          purchase.issued_at.strftime("%F")
        },
        "Quantity of Items" => ->(purchase) {
          purchase.line_items.total
        },
        "Variety of Items" => ->(purchase) {
          purchase.line_items.map(&:name).uniq.size
        },
        "Amount Spent" => ->(purchase) {
          purchase.amount_spent
        },
        "Spent on Diapers" => ->(purchase) {
          purchase.amount_spent_on_diapers
        },
        "Spent on Adult Incontinence" => ->(purchase) {
          purchase.amount_spent_on_adult_incontinence
        },
        "Spent on Period Supplies" => ->(purchase) {
          purchase.amount_spent_on_period_supplies
        },
        "Spent on Other" => ->(purchase) {
          purchase.amount_spent_on_other
        },
        "Comment" => ->(purchase) {
          purchase.comment
        }
      }
    end

    def base_headers
      base_table.keys
    end

    def item_headers
      return @item_headers if @item_headers

      item_names = Set.new

      purchases.each do |purchase|
        purchase.line_items.each do |line_item|
          item_names.add(line_item.item.name)
        end
      end

      @item_headers = item_names.sort
    end

    def build_row_data(purchase)
      row = base_table.values.map { |closure| closure.call(purchase) }

      row += Array.new(item_headers.size, 0)

      purchase.line_items.each do |line_item|
        item_name = line_item.item.name
        item_column_idx = headers_with_indexes[item_name]
        row[item_column_idx] += line_item.quantity
      end

      row
    end
  end
end
