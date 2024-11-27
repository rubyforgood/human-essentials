require 'time_util'
# == Schema Information
#
# Table name: distributions
#
#  id                     :integer          not null, primary key
#  agency_rep             :string
#  comment                :text
#  delivery_method        :integer          default("pick_up"), not null
#  issued_at              :datetime
#  reminder_email_enabled :boolean          default(FALSE), not null
#  shipping_cost          :decimal(8, 2)
#  state                  :integer          default("scheduled"), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  organization_id        :integer
#  partner_id             :integer
#  storage_location_id    :integer
#

class Distribution < ApplicationRecord
  has_paper_trail
  # Distributions are issued from a single storage location, so we associate
  # them so that on-hand amounts can be verified
  belongs_to :storage_location

  # Distributions are issued to a single partner
  belongs_to :partner
  belongs_to :organization

  # Distributions contain many different items
  include Itemizable
  include Exportable
  include IssuedAt
  include Filterable
  include ItemsHelper

  has_one :request, dependent: :nullify
  accepts_nested_attributes_for :request

  validates :storage_location, :partner, :organization, :delivery_method, presence: true
  validate :line_items_exist_in_inventory
  validate :line_items_quantity_is_positive
  validates :shipping_cost, numericality: { greater_than_or_equal_to: 0 }, allow_blank: true, if: :shipped?

  before_save :combine_distribution, :reset_shipping_cost

  enum state: { scheduled: 5, complete: 10 }
  enum delivery_method: { pick_up: 0, delivery: 1, shipped: 2 }
  scope :active, -> { joins(:line_items).joins(:items).where(items: { active: true }) }
  # add item_id scope to allow filtering distributions by item
  scope :by_item_id, ->(item_id) { joins(:items).where(items: { id: item_id }) }
  # partner scope to allow filtering by partner
  scope :by_item_category_id, ->(item_category_id) { joins(:items).where(items: { item_category_id: item_category_id }) }
  scope :by_partner, ->(partner_id) { where(partner_id: partner_id) }
  # location scope to allow filtering distributions by location
  scope :by_location, ->(storage_location_id) { where(storage_location_id: storage_location_id) }
  # state scope to allow filtering by state
  scope :by_state, ->(state) { where(state: state) }
  scope :recent, ->(count = 3) { order(issued_at: :desc).limit(count) }
  scope :future, -> { where("issued_at >= :tomorrow", tomorrow: Time.zone.tomorrow) }
  scope :during, ->(range) { where(distributions: { issued_at: range }) }
  scope :for_csv_export, ->(organization, filters = {}, date_range = nil) {
    where(organization: organization)
      .includes(:partner, :storage_location, :line_items)
      .apply_filters(filters, date_range)
  }
  scope :apply_filters, ->(filters, date_range) {
    includes(:partner, :storage_location, :line_items, :items)
      .order(issued_at: :desc)
      .class_filter(filters.merge(during: date_range))
  }
  scope :this_week, -> do
    where("issued_at > :start_date AND issued_at <= :end_date",
          start_date: Time.zone.today.beginning_of_week.beginning_of_day, end_date: Time.zone.today.end_of_week.end_of_day)
  end

  delegate :name, to: :partner, prefix: true

  def distributed_at
    if is_midnight(issued_at)
      issued_at.to_fs(:distribution_date)
    else
      issued_at.to_fs(:distribution_date_time)
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
    self.agency_rep = request.partner_user&.formatted_email
    self.comment = request.comments
    self.issued_at = Time.zone.today + 1.day
    request.request_items.each do |item|
      line_items.new(
        quantity: item["quantity"],
        item: Item.eager_load(:base_item).find_by(organization: request.organization, id: item["item_id"]),
        itemizable_id: request.id,
        itemizable_type: "Distribution"
      )
    end
  end

  def combine_distribution
    line_items.combine!
  end

  def csv_export_attributes
    [
      partner.name,
      issued_at.strftime("%F"),
      storage_location.name,
      total_quantity,
      cents_to_dollar(line_items.total_value),
      delivery_method,
      state,
      agency_rep
    ]
  end

  def future?
    issued_at > Time.zone.today
  end

  def past?
    issued_at < Time.zone.today
  end

  private

  def line_items_quantity_is_positive
    line_items_quantity_is_at_least(1)
  end

  def reset_shipping_cost
    self.shipping_cost = nil unless delivery_method == "shipped"
  end
end
