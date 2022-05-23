class DistributionFetchItemizedBreakdownService

  #
  # Initializes the DistributionFetchItemizedBreakdownService whoms
  # purpose to construct a itemized breakdown of items distributed
  # and what is left on-hand currently (at the time of running)
  #
  # @param organization [Organization]
  # @param distribution_ids [Array<Integer>]
  # @return [DistributionFetchItemizedBreakdownService] 
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

    # Inject the "onhand" metrics
    items_distributed.each do |item_name, value|
      items_distributed[item_name] = value.merge({
        current_onhand: current_onhand_quantities[item_name],
        onhand_minimum: current_onhand_minimums[item_name],
        below_onhand_minimum: current_onhand_quantities[item_name] < current_onhand_minimums[item_name]
      })
    end

    items_distributed
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
    item_breakdown = distributions.inject({}) do |acc, d| 
      d.line_items.each do |i| 
        key = i.item.name
        acc[key] ||= { distributed: 0 }
        acc[key][:distributed] += i.quantity
      end

      acc
    end
  end

end
