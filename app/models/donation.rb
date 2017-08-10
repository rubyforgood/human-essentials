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
#  issued_at                   :datetime
#

class Donation < ApplicationRecord
  SOURCES = { diaper_drive: "Diaper Drive", purchased: "Purchased Supplies", dropoff: "Donation Pickup Location", misc: "Misc. Donation" }.freeze

  belongs_to :organization

  belongs_to :dropoff_location, optional: true              # Validation is conditionally handled below.
  belongs_to :diaper_drive_participant, optional: true      # Validation is conditionally handled below.
  belongs_to :storage_location
  has_many :line_items, as: :itemizable, inverse_of: :itemizable do
    def combine!
      # Bail if there's nothing
      return if self.size == 0
      # First we'll collect all the line_items that are used
      combined = {}
      parent_id = first.itemizable_id
      each do |i|
        next unless i.valid?
        combined[i.item_id] ||= 0
        combined[i.item_id] += i.quantity
      end
      # Delete all the existing ones in this association -- this
      # method aliases to `delete_all`
      clear
      # And now recreate a new array of line_items using the corrected totals
      combined.each do |item_id,qty|
        build(quantity: qty, item_id: item_id, itemizable_id: parent_id)
      end
    end
  end
  has_many :items, through: :line_items
  accepts_nested_attributes_for :line_items,
    allow_destroy: true,
    :reject_if => proc { |li| li[:item_id].blank? && li[:quantity].blank? }

  before_create :combine_duplicates
  validates :dropoff_location, presence: { message: "must be specified since you chose '#{SOURCES[:dropoff]}'" }, if: :from_dropoff_location?
  validates :diaper_drive_participant, presence: { message: "must be specified since you chose '#{SOURCES[:diaper_drive]}'" }, if: :from_diaper_drive?
  validates :source, presence: true, inclusion: { in: SOURCES.values, message: "Must be a valid source." }

  include IssuedAt

  scope :during, ->(range) { where(donations: { issued_at: range }) }
  scope :by_source, ->(source) { source = SOURCES[source] if source.is_a?(Symbol); where(source: source)}
  scope :recent, ->(count=3) { order(:issued_at).limit(count) }

  def from_diaper_drive?
    source == SOURCES[:diaper_drive]
  end

  def from_dropoff_location?
    source == SOURCES[:dropoff]
  end

  def self.daily_quantities_by_source(start, stop)
    joins(:line_items).includes(:line_items).between(start, stop).group(:source).group_by_day("donations.created_at").sum("line_items.quantity")
  end

  def self.total_received
    self.includes(:line_items).map(&:total_quantity).reduce(0, :+)
  end

  ## TODO - Can this be simplified so that we can just pass it the donation_item_params hash?
  def track(item,quantity)
    if contains_item_id?(item.id)
      update_quantity(quantity, item)
    else
      LineItem.create(itemizable: self, item_id: item.id, quantity: quantity)
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

  def contains_item_id? id
    line_items.find_by(item_id: id).present?
  end

  ## TODO - Refactor this. "update" doesn't reflect that this "adds only"
  def update_quantity(q, i)
    line_item = self.line_items.find_by(item_id: i.id)
    line_item.quantity += q
    line_item.save
  end

private
  def combine_duplicates
    Rails.logger.info "Combining!"
    self.line_items.combine!
  end
end
