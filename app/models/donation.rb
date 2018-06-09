# == Schema Information
#
# Table name: donations
#
#  id                          :bigint(8)        not null, primary key
#  source                      :string
#  donation_site_id            :integer
#  created_at                  :datetime
#  updated_at                  :datetime
#  storage_location_id         :integer
#  comment                     :text
#  organization_id             :integer
#  diaper_drive_participant_id :integer
#  issued_at                   :datetime
#

class Donation < ApplicationRecord
  SOURCES = { diaper_drive: "Diaper Drive",
              donation_site: "Donation Site",
              misc: "Misc. Donation" }.freeze

  belongs_to :organization

  belongs_to :donation_site, optional: true # Validation is conditionally handled below.
  belongs_to :diaper_drive_participant, optional: proc { |d| d.from_diaper_drive? } # Validation is conditionally handled below.
  belongs_to :storage_location
  include Itemizable

  include Filterable
  scope :at_storage_location, ->(storage_location_id) {
    where(storage_location_id: storage_location_id)
  }
  scope :by_source, ->(source) { where(source: source) }
  scope :from_donation_site, ->(donation_site_id) { where(donation_site_id: donation_site_id) }
  scope :by_diaper_drive_participant, ->(diaper_drive_participant_id) {
    where(diaper_drive_participant_id: diaper_drive_participant_id)
  }

  before_create :combine_duplicates
  before_destroy :remove_inventory

  validates :donation_site, presence:
    { message: "must be specified since you chose '#{SOURCES[:donation_site]}'" },
                            if: :from_donation_site?
  validates :diaper_drive_participant, presence:
    { message: "must be specified since you chose '#{SOURCES[:diaper_drive]}'" },
                                       if: :from_diaper_drive?
  validates :source, presence: true, inclusion: { in: SOURCES.values,
                                                  message: "Must be a valid source." }

  include IssuedAt

  scope :during, ->(range) { where(donations: { issued_at: range }) }
  scope :by_source, ->(source) {
    source = SOURCES[source] if source.is_a?(Symbol)
    where(source: source)
  }
  scope :recent, ->(count = 3) { order(issued_at: :desc).limit(count) }

  def from_diaper_drive?
    source == SOURCES[:diaper_drive]
  end

  def from_donation_site?
    source == SOURCES[:donation_site]
  end

  def source_view
    from_diaper_drive? ? format_drive_name : source
  end

  def format_drive_name
    if diaper_drive_participant.name.present?
      "#{diaper_drive_participant.name} (diaper drive)"
    else
      source
    end
  end

  def self.daily_quantities_by_source(start, stop)
    joins(:line_items).includes(:line_items)
                      .between(start, stop)
                      .group(:source)
                      .group_by_day("donations.created_at")
                      .sum("line_items.quantity")
  end

  # def self.total_received
  #    self.includes(:line_items).map(&:total_quantity).reduce(0, :+)
  #  end

  def track(item, quantity)
    if contains_item_id?(item.id)
      update_quantity(quantity, item)
    else
      LineItem.create(itemizable: self, item_id: item.id, quantity: quantity)
    end
  end

  def remove(item)
    # doing this will handle either an id or an object
    item_id = item.to_i
    line_item = line_items.find_by(item_id: item_id)
    line_item&.destroy
  end

  def donation_site_view
    donation_site.nil? ? "N/A" : donation_site.name
  end

  def storage_view
    storage_location.nil? ? "N/A" : storage_location.name
  end

  def total_quantity
    line_items.sum(:quantity)
  end

  def contains_item_id?(id)
    line_items.find_by(item_id: id).present?
  end

  # Use a negative quantity to subtract inventory
  def update_quantity(quantity, item)
    item_id = item.to_i
    line_item = line_items.find_by(item_id: item_id)
    line_item.quantity += quantity
    # Inventory can never be negative
    line_item.quantity = 0 if line_item.quantity.negative?
    line_item.save
  end

  def remove_inventory
    storage_location.remove!(self)
  end

  private

  def combine_duplicates
    line_items.combine!
  end
end
