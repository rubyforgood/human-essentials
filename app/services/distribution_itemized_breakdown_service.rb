class DistributionItemizedBreakdownService
  #
  # Initializes the DistributionItemizedBreakdownService whoms
  # purpose to construct a itemized breakdown of items distributed
  # and what is left on-hand currently (at the time of running)
  #
  # @param organization [Organization]
  # @param distribution_ids [Array<Integer>]
  # @return [DistributionItemizedBreakdownService]
  def initialize(organization:, distribution_ids:)
    @organization = organization
    @distributions = organization.distributions.where(id: distribution_ids).includes(line_items: :item)
  end

  #
  # Returns a hash containing the itemized breakdown of
  # what was distributed.
  #
  # @return [Hash]
  def fetch
    items_distributed = fetch_items_distributed

    # Inject the "onhand" data
    items_distributed.each do |item_name, value|
      items_distributed[item_name] = value.merge({
        current_onhand: current_onhand_quantities[item_name],
        onhand_minimum: current_onhand_minimums[item_name],
        below_onhand_minimum: current_onhand_quantities[item_name] < current_onhand_minimums[item_name]
      })
    end

    items_distributed
  end

  #
  # Returns a CSV string representation of the itemized breakdown of
  # what was distributed
  #
  # @return [String]
  def fetch_csv
    convert_to_csv(fetch)
  end

  private

  attr_reader :organization, :distributions

  def current_onhand_quantities
    @current_onhand_quantities ||= organization.inventory_items.group("items.name").sum(:quantity)
  end

  def current_onhand_minimums
    @current_onhand_minimums ||= organization.inventory_items.group("items.name").maximum("items.on_hand_minimum_quantity")
  end

  def fetch_items_distributed
    distributions.each_with_object({}) do |d, acc|
      d.line_items.each do |i|
        key = i.item.name
        acc[key] ||= {distributed: 0}
        acc[key][:distributed] += i.quantity
      end
    end
  end

  def convert_to_csv(items_distributed_data)
    CSV.generate do |csv|
      csv << ["Item", "Total Distribution", "Total On Hand"]

      items_distributed_data.sort_by { |name, value| -value[:distributed] }.each do |key, value|
        csv << [key, value[:distributed], value[:current_onhand]]
      end
    end
  end
end
