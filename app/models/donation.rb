# == Schema Information
#
# Table name: donations
#
#  id                          :integer          not null, primary key
#  source                      :string
#  donation_site_id            :integer
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  storage_location_id         :integer
#  comment                     :text
#  organization_id             :integer
#  diaper_drive_participant_id :integer
#  issued_at                   :datetime
#  money_raised                :integer
#  manufacturer_id             :bigint(8)
#  diaper_drive_id             :bigint(8)
#

class Donation < ApplicationRecord
  SOURCES = { diaper_drive: "Diaper Drive",
              manufacturer: "Manufacturer",
              donation_site: "Donation Site",
              misc: "Misc. Donation" }.freeze

  belongs_to :organization

  belongs_to :donation_site, optional: true # Validation is conditionally handled below.
  belongs_to :diaper_drive_participant, optional: proc { |d| d.from_diaper_drive? } # Validation is conditionally handled below.
  belongs_to :diaper_drive, optional: true
  belongs_to :manufacturer, optional: proc { |d| d.from_manufacturer? } # Validation is conditionally handled below.
  belongs_to :storage_location
  include Itemizable

  include Filterable
  scope :at_storage_location, ->(storage_location_id) {
    where(storage_location_id: storage_location_id)
  }
  scope :from_donation_site, ->(donation_site_id) { where(donation_site_id: donation_site_id) }
  scope :by_diaper_drive_participant, ->(diaper_drive_participant_id) {
    where(diaper_drive_participant_id: diaper_drive_participant_id)
  }
  scope :from_manufacturer, ->(manufacturer_id) {
    where(manufacturer_id: manufacturer_id)
  }
  scope :for_csv_export, ->(organization) {
    where(organization: organization)
      .includes(:line_items, :storage_location, :donation_site)
      .order(created_at: :desc)
  }

  before_create :combine_duplicates

  validates :donation_site, presence:
    { message: "must be specified since you chose '#{SOURCES[:donation_site]}'" },
                            if: :from_donation_site?
  validates :diaper_drive_participant, presence:
    { message: "must be specified since you chose '#{SOURCES[:diaper_drive]}'" },
                                       if: :from_diaper_drive?
  validates :manufacturer, presence:
    { message: "must be specified since you chose '#{SOURCES[:manufacturer]}'" },
                           if: :from_manufacturer?
  validates :source, presence: true, inclusion: { in: SOURCES.values,
                                                  message: "Must be a valid source." }

  include IssuedAt

  # TODO: move this to Organization.donations as an extension
  scope :during, ->(range) { where(donations: { issued_at: range }) }
  scope :by_source, ->(source) {
    source = SOURCES[source] if source.is_a?(Symbol)
    where(source: source)
  }
  scope :recent, ->(count = 3) { order(issued_at: :desc).limit(count) }

  def from_diaper_drive?
    source == SOURCES[:diaper_drive]
  end

  def from_manufacturer?
    source == SOURCES[:manufacturer]
  end

  def from_donation_site?
    source == SOURCES[:donation_site]
  end

  def source_view
    from_diaper_drive? ? format_drive_name : source
  end

  def format_drive_name
    if diaper_drive_participant.contact_name.present?
      "#{diaper_drive_participant.contact_name} (diaper drive)"
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

  def replace_increase!(new_donation_params)
    old_data = to_a
    item_ids = line_items_attributes(new_donation_params).map { |i| i[:item_id].to_i }
    original_storage_location = storage_location

    ActiveRecord::Base.transaction do
      line_items.map(&:destroy!)
      reload
      Item.reactivate(item_ids)
      line_items_attributes(new_donation_params).map { |i| i.delete(:id) }
      update! new_donation_params
      # Roll back distribution output by increasing storage location
      storage_location.increase_inventory(to_a)
      # Apply the new changes to the storage location inventory
      original_storage_location.decrease_inventory(old_data)
      # TODO: Discuss this -- *should* we be removing InventoryItems when they hit 0 count?
      original_storage_location.inventory_items.where(quantity: 0).destroy_all
    end
  rescue ActiveRecord::RecordInvalid
    false
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

  def self.csv_export_headers
    ["Source", "Date", "Donation Site", "Storage Location", "Quantity of Items", "Variety of Items"]
  end

  def csv_export_attributes
    [
      source_view,
      issued_at.strftime("%F"),
      donation_site.try(:name),
      storage_location.name,
      line_items.total,
      line_items.size
    ]
  end

  private

  def combine_duplicates
    line_items.combine!
  end
end
