# == Schema Information
#
# Table name: organizations
#
#  id                       :integer          not null, primary key
#  city                     :string
#  deadline_day             :integer
#  default_storage_location :integer
#  email                    :string
#  intake_location          :integer
#  invitation_text          :text
#  latitude                 :float
#  longitude                :float
#  name                     :string
#  partner_form_fields      :text             default([]), is an Array
#  reminder_day             :integer
#  short_name               :string
#  state                    :string
#  street                   :string
#  url                      :string
#  zipcode                  :string
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#

class Organization < ApplicationRecord
  DIAPER_APP_LOGO = Rails.root.join("public", "img", "diaperbase-logo-full.png")

  validates :name, presence: true
  validates :short_name, presence: true, format: /\A[a-z0-9_]+\z/i
  validates :url, format: { with: URI::DEFAULT_PARSER.make_regexp, message: "it should look like 'http://www.example.com'" }, allow_blank: true
  validates :email, format: /[^@]+@[^@]+/, allow_blank: true
  validate :correct_logo_mime_type
  validates :deadline_day, numericality: { only_integer: true, less_than_or_equal_to: 28, greater_than_or_equal_to: 1, allow_nil: true }
  validates :reminder_day, numericality: { only_integer: true, less_than_or_equal_to: 14, greater_than_or_equal_to: 1, allow_nil: true }
  validate :deadline_after_reminder

  has_many :adjustments, dependent: :destroy
  has_many :barcode_items, dependent: :destroy do
    def all
      unscope(where: :organization_id).where("barcode_items.organization_id = ? OR barcode_items.barcodeable_type = ?", proxy_association.owner.id, "BaseItem")
    end
  end
  has_many :distributions, dependent: :destroy do
    def upcoming
      this_week.scheduled.where('issued_at >= ?', Time.zone.today)
    end
  end
  has_many :donations, dependent: :destroy
  has_many :purchases, dependent: :destroy
  has_many :donation_sites, dependent: :destroy
  has_many :diaper_drives, dependent: :destroy
  has_many :diaper_drive_participants, dependent: :destroy
  has_many :manufacturers, dependent: :destroy
  has_many :vendors, dependent: :destroy
  has_many :storage_locations, dependent: :destroy
  has_many :inventory_items, through: :storage_locations
  has_many :items, dependent: :destroy do
    def other
      where(partner_key: "other")
    end

    def during(date_start, date_end = Time.zone.now.strftime("%Y-%m-%d"))
      select("COUNT(line_items.id) as amount, name")
        .joins(:line_items)
        .where("line_items.created_at BETWEEN ? and ?", date_start, date_end)
        .group(:name)
    end

    def top(limit = 5)
      order('count(line_items.id) DESC')
        .limit(limit)
    end

    def bottom(limit = 5)
      order('count(line_items.id) ASC')
        .limit(limit)
    end
  end
  has_many :partners, dependent: :destroy
  has_many :transfers, dependent: :destroy
  has_many :users, dependent: :destroy
  has_many :requests, dependent: :destroy
  has_many :audits, dependent: :destroy
  before_update :update_partner_sections, if: :partner_form_fields_changed?

  ALL_PARTIALS = [
    ['Media Information', 'media_information'],
    ['Agency Stability', 'agency_stability'],
    ['Organizational Capacity', 'organizational_capacity'],
    ['Sources of Funding', 'sources_of_funding'],
    ['Population Served', 'population_served'],
    ['Executive Director', 'executive_director'],
    ['Diaper Pickup Person', 'diaper_pick_up_person'],
    ['Agency Distribution Information', 'agency_distribution_information'],
    ['Attached Documents', 'attached_documents']
  ].freeze

  has_rich_text :default_email_text

  has_one_attached :logo

  accepts_nested_attributes_for :users

  include Geocodable

  filterrific(
    available_filters: [
      :search_name
    ]
  )

  scope :alphabetized, -> { order(:name) }
  scope :search_name, ->(query) { where('name ilike ?', "%#{query}%") }

  # NOTE: when finding Organizations, use Organization.find_by(short_name: params[:organization_id])
  def to_param
    short_name
  end

  def display_users
    users.map(&:email).join(", ")
  end

  def ordered_requests
    requests.order(status: :asc, updated_at: :desc)
  end

  # Computes full address string based on street, city, state, and zip, adding ', ' and ' ' separators
  def address
    state_and_zip = [state, zipcode].select(&:present?).join(' ')
    [street, city, state_and_zip].select(&:present?).join(', ')
  end

  def address_changed?
    street_changed? || city_changed? || state_changed? || zipcode_changed?
  end

  def address_inline
    address.split("\n").map(&:strip).join(", ")
  end

  def total_inventory
    inventory_items.sum(:quantity) || 0
  end

  def self.seed_items(organization = Organization.all)
    base_items = BaseItem.all.map(&:to_h)
    Array.wrap(organization).each do |org|
      Rails.logger.info "\n\nSeeding #{org.name}'s items...\n"
      org.seed_items(base_items)
      org.reload
    end
  end

  def seed_items(item_collection)
    Array.wrap(item_collection).each do |item|
      items.create!(item)
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.info "[SEED] Duplicate item! #{e.record.name}"
      existing_item = items.find_by(name: e.record.name)
      if e.to_s.match(/been taken/).present? && existing_item.other?
        Rails.logger.info "Changing Item##{existing_item.id} from Other to #{e.record.partner_key}"
        existing_item.update(partner_key: e.record.partner_key)
        existing_item.reload
      else
        next
      end
    end
    reload
  end

  def logo_path
    if logo.attached?
      ActiveStorage::Blob.service.send(:path_for, logo.key).to_s
    else
      Organization::DIAPER_APP_LOGO.to_s
    end
  end

  def valid_items
    items.active.visible.map do |item|
      {
        id: item.id,
        partner_key: item.partner_key,
        name: item.name
      }
    end
  end

  def from_email
    email || get_admin_email
  end

  private

  def update_partner_sections
    PartnerFieldsJob.perform_async(id)
  end

  def correct_logo_mime_type
    if logo.attached? && !logo.content_type
                              .in?(%w(image/jpeg image/jpg image/pjpeg image/png image/x-png))
      self.logo = nil
      errors.add(:logo, "Must be a JPG or a PNG file")
    end
  end

  def deadline_after_reminder
    return if deadline_day.blank? || reminder_day.blank?

    errors.add(:deadline_day, "must be after the reminder date") if deadline_day < reminder_day
  end

  def get_admin_email
    User.where(organization_id: id, organization_admin: true).sample.email
  end
end
