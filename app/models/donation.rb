# == Schema Information
#
# Table name: donations
#
#  id                          :integer          not null, primary key
#  source                      :string
#  dropoff_location_id         :integer
#  created_at                  :datetime
#  updated_at                  :datetime
#  storage_location_id         :integer
#  comment                     :text
#  organization_id             :integer
#  diaper_drive_participant_id :integer
#

class Donation < ApplicationRecord
  SOURCES = { diaper_drive: "Diaper Drive", purchased: "Purchased Supplies", dropoff: "Donation Pickup Location", misc: "Misc. Donation" }.freeze

  belongs_to :organization

  belongs_to :dropoff_location, optional: true              # Validation is conditionally handled below.
  belongs_to :diaper_drive_participant, optional: true      # Validation is conditionally handled below.
  belongs_to :storage_location
  has_many :line_items, as: :itemizable, inverse_of: :itemizable
  has_many :items, through: :line_items
  accepts_nested_attributes_for :line_items,
    allow_destroy: true

  validates :dropoff_location, presence: { message: "must be specified since you chose 'Donation Pickup Location'" }, if: :from_dropoff_location?
  validates :diaper_drive_participant, presence: { message: "must be specified since you chose 'Diaper Drive'" }, if: :from_diaper_drive?
  validates :source, presence: true, inclusion: { in: SOURCES.values, message: "Must be a valid source." }
  # FIXME - This validation can be removed because it's implicit in belongs_to as of Rails 5
  validates :storage_location, :organization, presence: true

  scope :between, ->(start, stop) { where(donations: { created_at: start..stop }) }
  scope :during, ->(range) { where(donations: { created_at: range }) }
  # TODO - change this to "by_source()" with an argument that accepts a source name
  scope :diaper_drive, -> { where(source: "Diaper Drive") }
  scope :recent, ->(count=3) { order(:created_at).limit(count) }

  def from_diaper_drive?
    source == "Diaper Drive"
  end

  def from_dropoff_location?
    source == "Donation Pickup Location"
  end

  def self.daily_quantities_by_source(start, stop)
    joins(:line_items).includes(:line_items).between(start, stop).group(:source).group_by_day("donations.created_at").sum("line_items.quantity")
  end

  def self.total_received
    self.includes(:line_items).map(&:total_quantity).reduce(0, :+)
  end

  ## TODO - Can this be simplified so that we can just pass it the donation_item_params hash?
  def track(item,quantity)
    if !check_existence(item.id)
      LineItem.create(itemizable: self, item_id: item.id, quantity: quantity)
    else
      update_quantity(quantity, item)
    end
  end

  ## TODO - Test coverage for this method
  def remove(item_id)
    line_item = self.line_items.find_by(item_id: item_id)
    if (line_item)
      line_item.destroy
    end
  end

  def total_quantity
    self.line_items.sum(:quantity)
  end

  ## TODO - Could this be made a member method "count" of the `items` association?
  def total_items
    self.line_items.collect{ | c | c.quantity }.reduce(:+)
  end

  ## TODO - This should check for existence of the item first. Also, I think there's a to_line_item method in Barcode, isn't there?
  def track_from_barcode(barcode_hash)
    LineItem.create(itemizable: self, item_id: barcode_hash[:item_id], quantity: barcode_hash[:quantity])
  end

  ## TODO - This can be refactored to just the find_by query; should also be made a predicate [contains_item_id?()]
  def check_existence(id)
    if line_item = self.line_items.find_by(item_id: id)
      true
    else
      false
    end
  end

  ## TODO - Refactor this. "update" doesn't reflect that this "adds only"
  def update_quantity(q, i)
    line_item = self.line_items.find_by(item_id: i.id)
    line_item.quantity += q
    line_item.save
  end

end
