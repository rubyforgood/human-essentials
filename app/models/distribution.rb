require 'time_util'
# == Schema Information
#
# Table name: distributions
#
#  id                          :integer          not null, primary key
#  agency_rep                  :string
#  comment                     :text
#  issued_at                   :datetime
#  issued_at_end               :datetime
#  issued_at_timeframe_enabled :boolean          default(FALSE)
#  reminder_email_enabled      :boolean          default(FALSE), not null
#  state                       :integer          default("started"), not null
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  organization_id             :integer
#  partner_id                  :integer
#  storage_location_id         :integer
#

class Distribution < ApplicationRecord
  # Distributions are issued from a single storage location, so we associate
  # them so that on-hand amounts can be verified
  belongs_to :storage_location

  # Distributions are issued to a single partner
  belongs_to :partner
  belongs_to :organization

  # Distributions contain many different items
  include Itemizable

  has_one :request, dependent: :nullify
  accepts_nested_attributes_for :request

  validates :storage_location, :partner, :organization, presence: true
  validate :line_item_items_exist_in_inventory
  validate :issued_at_end_is_after_issued_at
  include IssuedAt

  before_save :combine_distribution

  enum state: { started: 0, scheduled: 5, complete: 10 }

  include Filterable
  # add item_id scope to allow filtering distributions by item
  scope :by_item_id, ->(item_id) { joins(:items).where(items: { id: item_id }) }
  # partner scope to allow filtering by partner
  scope :by_partner, ->(partner_id) { where(partner_id: partner_id) }
  scope :recent, ->(count = 3) { order(issued_at: :desc).limit(count) }
  scope :future, -> { where("issued_at >= :tomorrow", tomorrow: Time.zone.tomorrow) }
  scope :during, ->(range) { where(distributions: { issued_at: range }) }
  scope :for_csv_export, ->(organization) {
    where(organization: organization)
      .includes(:partner, :storage_location, :line_items)
  }
  scope :this_week, -> do
    where("issued_at > :start_date AND issued_at <= :end_date",
          start_date: Time.zone.today.beginning_of_week.beginning_of_day, end_date: Time.zone.today.end_of_week.end_of_day)
  end

  delegate :name, to: :partner, prefix: true

  def distributed_at
    if is_midnight(issued_at)
      issued_at.to_s(:distribution_date)
    else
      issued_at.to_s(:distribution_date_time)
    end
  end

  def combine_duplicates
    Rails.logger.info "Combining!"
    line_items.combine!
  end

  def copy_line_items(donation_id)
    line_items = LineItem.where(itemizable_id: donation_id, itemizable_type: "Donation")
    line_items.each do |line_item|
      self.line_items.new(line_item.attributes)
    end
  end

  def copy_from_donation(donation_id, storage_location_id)
    copy_line_items(donation_id) if donation_id
    self.storage_location = StorageLocation.find(storage_location_id) if storage_location_id
  end

  def copy_from_request(request_id)
    request = Request.find(request_id)
    self.request = request
    self.organization_id = request.organization_id
    self.partner_id = request.partner_id
    self.comment = request.comments
    self.issued_at = Time.zone.today + 1.day
    request.request_items.each do |item|
      line_items.new(
        quantity: item["quantity"],
        item: Item.joins(:inventory_items).eager_load(:base_item).find_by(organization: request.organization, id: item["item_id"]),
        itemizable_id: request.id,
        itemizable_type: "Distribution"
      )
    end
  end

  def self.csv_export_headers
    ["Partner", "Date of Distribution", "Source Inventory", "Total items"]
  end

  def combine_distribution
    line_items.combine!
  end

  def csv_export_attributes
    [
      partner.name,
      issued_at.strftime("%F"),
      storage_location.name,
      line_items.total
    ]
  end

  def future?
    issued_at > Time.zone.today
  end

  def past?
    issued_at < Time.zone.today
  end

  def issued_at_end_is_after_issued_at
    if issued_at_timeframe_enabled
      start_time = issued_at
      end_time = issued_at_end
      if start_time > end_time
        errors.add(:issued_at_end, "can't be before issued at")
      end
    end
  end
end
