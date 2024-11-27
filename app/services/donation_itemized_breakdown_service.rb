# frozen_string_literal: true

class DonationItemizedBreakdownService
  #
  # Initialize the DonationItemizedBreakdownService
  #
  # @param organization [Organization]
  # @param donation_ids [Array<Integer>]
  # @return [DonationItemizedBreakdownService]
  def initialize(organization:, donation_ids:)
    @organization = organization
    @donation_ids = donation_ids
  end

  def fetch
    inventory = nil
    if Event.read_events?(@organization)
      inventory = View::Inventory.new(@organization.id)
    end
    items_donated = fetch_items_donated
    current_onhand = current_onhand_quantities(inventory)

    items_donated.map! do |item|
      item_name = item[:name]
      {
        current_onhand: current_onhand[item_name],
        name: item_name,
        donated: item[:donated]
      }
    end

    items_donated.sort_by { |item| item[:name] }
  end

  private

  attr_reader :organization, :donation_ids

  def donations
    @donations ||= Donation.where(id: donation_ids).includes(line_items: :item)
  end

  def current_onhand_quantities(inventory)
    if inventory
      inventory.all_items.group_by(&:name).to_h { |k, v| [k, v.sum(&:quantity)] }
    else
      organization.inventory_items.group("items.name").sum(:quantity)
    end
  end

  def fetch_items_donated
    item_donation_hash = donations.each_with_object({}) do |d, acc|
      d.line_items.each do |i|
        key = i.item.name
        acc[key] ||= {donated: 0}
        acc[key][:donated] += i.quantity
      end
    end

    item_donation_hash.map { |k, v| v.merge(name: k) }
  end
end
