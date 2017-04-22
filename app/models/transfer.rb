class Transfer < ActiveRecord::Base
  belongs_to :from, :class_name => 'Inventory', :foreign_key => :from_id
  belongs_to :to, :class_name => 'Inventory', :foreign_key => :to_id

  has_many :containers, as: :itemizable, inverse_of: :itemizable
  has_many :items, through: :containers
  accepts_nested_attributes_for :containers,
    allow_destroy: true

  validates :from, :to, presence: true
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
      holding = self.from.holdings.find_by(item: container.item)
      if holding.nil?
        errors.add(:inventory,
                   "#{container.item.name} is not available " \
                   "at this storage location")
      end
    end
  end


end