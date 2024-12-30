module Exports
  class ExportDonationsCSVService
    def initialize(donation_ids:, organization:)
      # Use a where lookup so that I can eager load all the resources
      # needed rather than depending on external code to do it for me.
      # This makes this code more self contained and efficient!
      @donations = Donation.includes(
        :storage_location,
        :donation_site,
        :product_drive,
        :product_drive_participant,
        line_items: [:item]
      ).where(
        id: donation_ids,
      ).order(created_at: :asc)
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
      donations.each do |donation|
        csv_data << build_row_data(donation)
      end

      csv_data
    end

    private

    attr_reader :donations

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
    # donation.
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
        "Source" => ->(donation) {
          donation.source
        },
        "Date" => ->(donation) {
          donation.issued_at.strftime("%F")
        },
        "Details" => ->(donation) {
          donation.details
        },
        "Storage Location" => ->(donation) {
          donation.storage_view
        },
        "Quantity of Items" => ->(donation) {
          donation.line_items.total
        },
        "Variety of Items" => ->(donation) {
          donation.line_items.map(&:name).uniq.size
        },
        "In-Kind Total" => ->(donation) {
          donation.in_kind_value_money
        },
        "Comments" => ->(donation) {
          donation.comment
        }
      }
    end

    def base_headers
      base_table.keys
    end

    def item_headers
      return @item_headers if @item_headers

      item_names = Set.new

      donations.each do |donation|
        donation.line_items.each do |line_item|
          item_names.add(line_item.item.name)
        end
      end

      @item_headers = item_names.sort
      @item_headers = @item_headers.flat_map { |h| [h, "#{h} In-Kind Value"] } if @organization.include_in_kind_values_in_exported_files

      @item_headers
    end

    def build_row_data(donation)
      row = base_table.values.map { |closure| closure.call(donation) }

      row += make_item_quantity_and_value_slots

      donation.line_items.each do |line_item|
        item_name = line_item.item.name
        item_column_idx = headers_with_indexes[item_name]
        row[item_column_idx] += line_item.quantity
        row[item_column_idx + 1] += Money.new(line_item.value_per_line_item) if @organization.include_in_kind_values_in_exported_files
      end

      convert_to_dollar(row)
    end

    def make_item_quantity_and_value_slots
      slots = Array.new(item_headers.size, 0)
      slots = slots.map.with_index { |value, index| index.odd? ? Money.new(0) : value } if @organization.include_in_kind_values_in_exported_files
      slots
    end

    def convert_to_dollar(row)
      row.map do |column|
        column.is_a?(Money) ? column.to_f : column
      end
    end
  end
end
