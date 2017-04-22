# == Schema Information
#
# Table name: donations
#
#  id                  :integer          not null, primary key
#  source              :string
#  completed           :boolean          default(FALSE)
#  dropoff_location_id :integer
#  created_at          :datetime
#  updated_at          :datetime
#

class Donation < ActiveRecord::Base
  belongs_to :dropoff_location
  has_many :containers, as: :itemizable, inverse_of: :itemizable
  belongs_to :inventory
  has_many :items, through: :containers

  validates :dropoff_location, presence: true
  validates :source, presence: true

  scope :completed, -> { where(completed: true) }
  scope :incomplete, -> { where(completed: false) }
  scope :between, ->(start, stop) { where(donations: { created_at: start..stop }) }
  scope :diaper_drive, -> { where(source: "Diaper Drive") }

  def self.daily_quantities_by_source(start, stop)
    joins(:containers).includes(:containers).between(start, stop).group(:source).group_by_day("donations.created_at").sum("containers.quantity")
  end

  def track(item,quantity)
    if !check_existence(item.id)
      Container.create(itemizable: self, item_id: item.id, quantity: quantity)
    else
      update_quantity(quantity, item)
    end
  end

  def total_items()
    self.containers.collect{ | c | c.quantity }.reduce(:+)
  end

  def track_from_barcode(barcode_hash)
    Container.create(itemizable: self, item_id: barcode_hash[:item_id], quantity: barcode_hash[:quantity])
  end

  def check_existence(id)
    if container = self.containers.find_by(item_id: id)
      true
    else
      false
    end
  end

  def update_quantity(q, i)
    container = self.containers.find_by(item_id: i.id)
    container.quantity += q
    container.save
  end

  def complete
    self.completed = true
    self.save
  end

end
