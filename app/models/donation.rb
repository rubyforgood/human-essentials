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
  include Itemizable

  include Filterable
  scope :at_storage_location, ->(storage_location_id) { where(storage_location_id: storage_location_id) }
  scope :by_source, ->(source) { where(source: source) }
  scope :from_dropoff_location, ->(dropoff_location_id) { where(dropoff_location_id: dropoff_location_id) }
  scope :by_diaper_drive_participant, ->(diaper_drive_participant_id) { where(diaper_drive_participant_id: diaper_drive_participant_id) }

  before_create :combine_duplicates
  before_destroy :remove_inventory

  validates :dropoff_location, presence: { message: "must be specified since you chose '#{SOURCES[:dropoff]}'" }, if: :from_dropoff_location?
  validates :diaper_drive_participant, presence: { message: "must be specified since you chose '#{SOURCES[:diaper_drive]}'" }, if: :from_diaper_drive?
  validates :source, presence: true, inclusion: { in: SOURCES.values, message: "Must be a valid source." }

  include IssuedAt

  scope :during, ->(range) { where(donations: { issued_at: range }) }
  scope :by_source, ->(source) { source = SOURCES[source] if source.is_a?(Symbol); where(source: source)}
  scope :recent, ->(count = 3) { order(issued_at: :desc).limit(count) }

  def from_diaper_drive?
    source == SOURCES[:diaper_drive]
  end

  def from_dropoff_location?
    source == SOURCES[:dropoff]
  end

  def source_view
    from_diaper_drive? ? format_drive_name : source
  end

  def format_drive_name
    diaper_drive_participant.name.present? ? "#{diaper_drive_participant.name} (diaper drive)" : source
  end

  def self.daily_quantities_by_source(start, stop)
    joins(:line_items).includes(:line_items).between(start, stop).group(:source).group_by_day("donations.created_at").sum("line_items.quantity")
  end

  #def self.total_received
#    self.includes(:line_items).map(&:total_quantity).reduce(0, :+)
#  end

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

  def dropoff_view
    dropoff_location.nil? ? "N/A" : dropoff_location.name
  end

  def storage_view
    storage_location.nil? ? "N/A" : storage_location.name
  end

  def total_quantity
    self.line_items.sum(:quantity)
  end


  ## TODO - This should check for existence of the item first. Also, I think there's a to_h method in Barcode, isn't there?
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

  def remove_inventory
    storage_location.remove!(self)
  end

private
  def combine_duplicates
    Rails.logger.info "Combining!"
    self.line_items.combine!
  end
end
