# == Schema Information
#
# Table name: donations
#
#  id                           :integer          not null, primary key
#  comment                      :text
#  issued_at                    :datetime
#  money_raised                 :integer
#  source                       :string
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  donation_site_id             :integer
#  manufacturer_id              :bigint
#  organization_id              :integer
#  product_drive_id             :bigint
#  product_drive_participant_id :integer
#  storage_location_id          :integer
#

class Donation < ApplicationRecord
  has_paper_trail
  SOURCES = { product_drive: "Product Drive",
              manufacturer: "Manufacturer",
              donation_site: "Donation Site",
              misc: "Misc. Donation" }.freeze
  SOURCES.values.map(&:freeze)

  belongs_to :organization

  belongs_to :donation_site, optional: true # Validation is conditionally handled below.
  belongs_to :product_drive_participant, optional: proc { |d| d.from_product_drive? } # Validation is conditionally handled below.
  belongs_to :product_drive, optional: true
  belongs_to :manufacturer, optional: proc { |d| d.from_manufacturer? } # Validation is conditionally handled below.
  belongs_to :storage_location

  include Itemizable
  include Exportable
  include Filterable
  include IssuedAt

  scope :at_storage_location, ->(storage_location_id) {
    where(storage_location_id: storage_location_id)
  }
  scope :from_donation_site, ->(donation_site_id) { where(donation_site_id: donation_site_id) }
  scope :by_product_drive, ->(product_drive_id) {
    where(product_drive_id: product_drive_id)
  }
  scope :by_product_drive_participant, ->(product_drive_participant_id) {
    where(product_drive_participant_id: product_drive_participant_id)
  }
  scope :from_manufacturer, ->(manufacturer_id) {
    where(manufacturer_id: manufacturer_id)
  }
  scope :for_csv_export, ->(organization, *) {
    where(organization: organization)
      .includes(:line_items, :storage_location, :donation_site)
      .order(created_at: :desc)
  }

  before_create :combine_duplicates

  validates :donation_site, presence:
    { message: "must be specified since you chose '#{SOURCES[:donation_site]}'" }, if: :from_donation_site?
  validates :product_drive, presence:
    { message: "must be specified since you chose '#{SOURCES[:product_drive]}'" }, if: :from_product_drive?
  validates :manufacturer, presence:
    { message: "must be specified since you chose '#{SOURCES[:manufacturer]}'" }, if: :from_manufacturer?
  validates :source, presence: true, inclusion: { in: SOURCES.values, message: "Must be a valid source." }

  # TODO: move this to Organization.donations as an extension
  scope :during, ->(range) { where(donations: { issued_at: range }) }
  scope :by_source, ->(source) {
    return where(source: source) unless source.is_a?(Symbol)

    includes(source).where(source: SOURCES[source])
  }
  scope :recent, ->(count = 3) { order(issued_at: :desc).limit(count) }

  scope :active, -> { joins(:line_items).joins(:items).where(items: { active: true }) }

  def from_product_drive?
    source == SOURCES[:product_drive]
  end

  def from_manufacturer?
    source == SOURCES[:manufacturer]
  end

  def from_donation_site?
    source == SOURCES[:donation_site]
  end

  def source_view
    return source unless from_product_drive?

    product_drive_participant&.donation_source_view || product_drive.donation_source_view
  end

  def self.daily_quantities_by_source(start, stop)
    joins(:line_items).includes(:line_items)
                      .between(start, stop)
                      .group(:source)
                      .group_by_day("donations.created_at")
                      .sum("line_items.quantity")
  end

  def details
    case source
    when SOURCES[:product_drive]
      product_drive.name
    when SOURCES[:manufacturer]
      manufacturer.name
    when SOURCES[:donation_site]
      donation_site.name
    when SOURCES[:misc]
      comment&.truncate(25, separator: /\s/)
    end
  end

  def remove(item)
    # doing this will handle either an id or an object
    item_id = item.to_i
    line_item = line_items.find_by(item_id: item_id)
    line_item&.destroy
  end

  def money_raised_in_dollars
    money_raised.to_d / 100
  end

  def donation_site_view
    donation_site.nil? ? "N/A" : donation_site.name
  end

  def storage_view
    storage_location.nil? ? "N/A" : storage_location.name
  end

  private

  def combine_duplicates
    line_items.combine!
  end
end
