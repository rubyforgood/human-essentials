require 'time_util'
# == Schema Information
#
# Table name: distributions
#
#  id                  :bigint(8)        not null, primary key
#  comment             :text
#  created_at          :datetime
#  updated_at          :datetime
#  storage_location_id :integer
#  partner_id          :integer
#  organization_id     :integer
#  issued_at           :datetime
#  agency_rep          :string
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

  include IssuedAt

  before_save :combine_distribution

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
    where("issued_at >= :start_date AND issued_at <= :end_date",
          start_date: Time.zone.today, end_date: Time.zone.today.sunday)
  end

  delegate :name, to: :partner, prefix: true

  # TODO: kill me
  def replace_distribution!(new_distribution_params)
    ActiveRecord::Base.transaction do
      # fixed_distribution_params = new_distribution_params["line_items_attributes"].to_h.values.reject { |f| f["item_id"].blank? && f["quantity"].blank? }
      # Roll back distribution output by increasing storage location
      storage_location.increase_inventory(to_a)
      # Delete the line items -- they'll be replaced later
      line_items.each(&:destroy!)
      reload

      # Replace the current distribution with the new parameters
      update! new_distribution_params
      reload
      # Apply the new changes to the storage location inventory
      storage_location.decrease_inventory(to_a)
    end
  rescue ActiveRecord::RecordInvalid
    false
  end

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
end
