# == Schema Information
#
# Table name: tickets
#
#  id           :integer          not null, primary key
#  created_at   :datetime
#  updated_at   :datetime
#  partner_id   :integer
#  inventory_id :integer
#

class Ticket < ActiveRecord::Base

  # Tickets are issued from a single inventory, so we associate them so that
  # on-hand amounts can be verified
  belongs_to :inventory

  # Tickets are issued to a single partner
  belongs_to :partner

  # Tickets contain many different items
  has_many :containers, as: :itemizable, inverse_of: :itemizable
  has_many :items, through: :containers
  accepts_nested_attributes_for :containers,
    allow_destroy: true

  validates :inventory, :partner, presence: true
  validates_associated :containers
  validate :container_items_exist_in_inventory

  def quantities_by_category
    containers.includes(:item).group("items.category").sum(:quantity)
  end

  def sorted_containers
    containers.includes(:item).order("items.name")
  end

  def total_quantity
    containers.sum(:quantity)
  end

  private

  def container_items_exist_in_inventory
    self.containers.each do |container|
      next unless container.item
      holding = self.inventory.holdings.find_by(item: container.item)
      if holding.nil?
        errors.add(:inventory,
                   "#{container.item.name} is not available " \
                   "at this storage location")
      end
    end
  end
end
