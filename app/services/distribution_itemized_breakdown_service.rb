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
    @distribution_ids = distribution_ids
  end

  #
  # Returns a hash containing the itemized breakdown of
  # what was distributed.
  #
  # @return [Array]
  def fetch
    inventory = nil
    if Event.read_events?(@organization)
      inventory = View::Inventory.new(@organization.id)
    end
    current_onhand = current_onhand_quantities(inventory)
    current_min_onhand = current_onhand_minimums(inventory)
    items_distributed = fetch_items_distributed

    # Inject the "onhand" data
    items_distributed.map! do |item|
      item_name = item[:name]

      below_onhand_minimum = if current_onhand[item_name] && current_min_onhand[item_name]
        current_onhand[item_name] < current_min_onhand[item_name]
      end

      item.merge({
        current_onhand: current_onhand[item_name],
        onhand_minimum: current_min_onhand[item_name],
        below_onhand_minimum: below_onhand_minimum
      })
    end

    items_distributed.sort_by { |item| item[:name] }
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

  attr_reader :organization, :distribution_ids

  def distributions
    @distributions ||= organization.distributions.where(id: distribution_ids).includes(line_items: :item)
  end

  def current_onhand_quantities(inventory)
    if inventory
      inventory.all_items.group_by(&:name).to_h { |k, v| [k, v.sum(&:quantity)] }
    else
      organization.inventory_items.group("items.name").sum(:quantity)
    end
  end

  def current_onhand_minimums(inventory)
    if inventory
      inventory.all_items.group_by(&:name).to_h { |k, v| [k, v.map(&:on_hand_minimum_quantity).max] }
    else
      organization.inventory_items.group("items.name").maximum("items.on_hand_minimum_quantity")
    end
  end

  def fetch_items_distributed
    item_distribution_hash = distributions.each_with_object({}) do |d, acc|
      d.line_items.each do |i|
        key = i.item.name
        acc[key] ||= {distributed: 0}
        acc[key][:distributed] += i.quantity
      end
    end

    item_distribution_hash.map { |k, v| v.merge(name: k) }
  end

  def convert_to_csv(items_distributed_data)
    CSV.generate do |csv|
      csv << ["Item", "Total Distribution", "Total On Hand"]

      items_distributed_data.each do |item|
        csv << [item[:name], item[:distributed], item[:current_onhand]]
      end
    end
  end
end
