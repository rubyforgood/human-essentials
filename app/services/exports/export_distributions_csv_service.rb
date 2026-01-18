# Don't technically need to pull in csv for the code itself,
# but this ensures that the unit test can run in isolation
require 'csv'

module Exports
  class ExportDistributionsCSVService
    include DistributionHelper
    include ItemsHelper

    def initialize(distributions:, organization:, filters: [])
      # Currently, the @distributions are already loaded by the controllers that are delegating exporting
      # to this service object; this is happening within the same request/response cycle, so it's already
      # in memory, so we can pass that collection in directly. Should this be moved to a background / async
      # job, we will need to pass in a collection of IDs instead.
      # Also, adding in a `filters` parameter to make the filters that have been used available to this
      # service object.
      @distributions = distributions
      @filters = filters
      @organization = organization
      @distribution_totals = DistributionTotalsService.call(Distribution.where(organization:).class_filter(filters))
    end

    def generate_csv
      csv_data = generate_csv_data

      CSV.generate(headers: true) do |csv|
        csv_data.each { |row| csv << row }
      end
    end

    def generate_csv_data
      csv_data = []

      csv_data << base_headers + item_headers
      distributions.each do |distribution|
        csv_data << build_row_data(distribution)
      end

      csv_data
    end

    private

    attr_reader :distributions

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
        "Initial Allocation" => ->(distribution) {
          distribution.created_at.strftime("%m/%d/%Y")
        },
        "Scheduled for" => ->(distribution) {
          (distribution.issued_at.presence || distribution.created_at).strftime("%m/%d/%Y")
        },
        "Source Inventory" => ->(distribution) {
          distribution.storage_location.name
        },
        item_quantity_header_col_name => ->(distribution) {
          @distribution_totals[distribution.id]&.quantity || 0
        },
        item_value_header_col_name => ->(distribution) {
          cents_to_dollar(@distribution_totals[distribution.id]&.value || 0)
        },
        "Delivery Method" => ->(distribution) {
          distribution.delivery_method
        },
        "Shipping Cost" => ->(distribution) {
          distribution_shipping_cost(distribution.shipping_cost)
        },
        "Status" => ->(distribution) {
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
    def item_quantity_header_col_name
      if @filters[:by_item_id].present?
        "Total Number of #{filtered_item_name}"
      elsif @filters[:by_item_category_id].present?
        "Total Number of #{filtered_item_category_name}"
      else
        "Total Items"
      end
    end

    def item_value_header_col_name
      if @filters[:by_item_id].present?
        "Total Value of #{filtered_item_name}"
      elsif @filters[:by_item_category_id].present?
        "Total Value of #{filtered_item_category_name}"
      else
        "Total Value"
      end
    end

    def filtered_item_name
      @filtered_item ||= Item.find(@filters[:by_item_id].to_i).name
    end

    def filtered_item_category_name
      @filtered_item_category ||= ItemCategory.find(@filters[:by_item_category_id].to_i).name
    end

    def base_headers
      base_table.keys
    end

    def item_names
      @item_names ||= @organization.items.pluck(:name).sort_by(&:downcase)
    end

    def item_headers
      in_kind_value_headers = @organization.include_in_kind_values_in_exported_files ? item_names.map { |item| "#{item} In-Kind Value" } : []
      package_headers = @organization.include_packages_in_distribution_export ? item_names.map { |item| "#{item} Packages" } : []
      item_names.zip(in_kind_value_headers, package_headers).flatten.compact
    end

    def build_row_data(distribution)
      row = base_table.values.map { |closure| closure.call(distribution) }

      item_names.each do |item_name|
        # We are doing this in-memory so that we can use the already-loaded line item records
        line_items = distribution.line_items.select { |item| item.name == item_name }

        row << line_items.sum(&:quantity)
        row << Money.new(line_items.sum(&:value_per_line_item)) if @organization.include_in_kind_values_in_exported_files
        row << line_items.map(&:has_packages).compact.sum.round(2) if @organization.include_packages_in_distribution_export
      end

      row
    end
  end
end
