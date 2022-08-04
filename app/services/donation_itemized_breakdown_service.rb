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
    items_donated_hash.map do |item_name, hash|
      {
        current_onhand: current_onhand_quantities[item_name],
        name: item_name,
        donated: hash[:donated]
      }
    end
  end

  private

  attr_reader :organization, :donation_ids

  def donations
    @donations ||= Donation.where(id: donation_ids).includes(line_items: :item)
  end

  def current_onhand_quantities
    @current_onhand_quantities ||= organization.inventory_items.group("items.name").sum(:quantity)
  end

  def items_donated_hash
    donations.each_with_object({}) do |d, acc|
      d.line_items.each do |i|
        key = i.item.name
        acc[key] ||= {donated: 0}
        acc[key][:donated] += i.quantity
      end
    end
  end
end
