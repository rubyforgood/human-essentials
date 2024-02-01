# == Schema Information
#
# Table name: organizations
#
#  id                                                 :integer          not null, primary key
#  city                                               :string
#  deadline_day                                       :integer
#  default_storage_location                           :integer
#  distribute_monthly                                 :boolean          default(FALSE), not null
#  email                                              :string
#  enable_child_based_requests                        :boolean          default(TRUE), not null
#  enable_individual_requests                         :boolean          default(TRUE), not null
#  enable_quantity_based_requests                     :boolean          default(TRUE), not null
#  intake_location                                    :integer
#  invitation_text                                    :text
#  latitude                                           :float
#  longitude                                          :float
#  name                                               :string
#  partner_form_fields                                :text             default([]), is an Array
#  reminder_day                                       :integer
#  repackage_essentials                               :boolean          default(FALSE), not null
#  short_name                                         :string
#  state                                              :string
#  street                                             :string
#  url                                                :string
#  use_single_step_invite_and_approve_partner_process :boolean          default(FALSE), not null
#  ytd_on_distribution_printout                       :boolean          default(TRUE), not null
#  zipcode                                            :string
#  created_at                                         :datetime         not null
#  updated_at                                         :datetime         not null
#  account_request_id                                 :integer
#  ndbn_member_id                                     :bigint
#

class Organization < ApplicationRecord
  has_paper_trail
  resourcify

  DIAPER_APP_LOGO = Rails.root.join("public", "img", "humanessentials_logo.png")

  include Deadlinable

  validates :name, presence: true
  validates :short_name, presence: true, format: /\A[a-z0-9_]+\z/i, uniqueness: true
  validates :url, format: { with: URI::DEFAULT_PARSER.make_regexp, message: "it should look like 'http://www.example.com'" }, allow_blank: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validate :correct_logo_mime_type
  validate :some_request_type_enabled
  validate :logo_size_check, if: proc { |org| org.logo.attached? }

  belongs_to :account_request, optional: true
  belongs_to :ndbn_member, class_name: 'NDBNMember', optional: true

  with_options dependent: :destroy do
    has_many :adjustments
    has_many :annual_reports
    has_many :audits
    has_many :product_drive_participants
    has_many :product_drives
    has_many :donation_sites
    has_many :donations
    has_many :manufacturers
    has_many :partners
    has_many :partner_groups
    has_many :purchases
    has_many :requests
    has_many :storage_locations
    has_many :inventory_items, through: :storage_locations
    has_many :kits
    has_many :transfers
    has_many :users, -> { distinct }, through: :roles
    has_many :vendors
  end

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
  has_many :item_categories, dependent: :destroy
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

  after_create do
    account_request&.update!(status: "admin_approved")
  end

  ALL_PARTIALS = [
    ['Media Information', 'media_information'],
    ['Agency Stability', 'agency_stability'],
    ['Organizational Capacity', 'organizational_capacity'],
    ['Sources of Funding', 'sources_of_funding'],
    ['Area Served', 'area_served'],
    ['Population Served', 'population_served'],
    ['Executive Director', 'executive_director'],
    ['Pickup Person', 'pick_up_person'],
    ['Agency Distribution Information', 'agency_distribution_information'],
    ['Attached Documents', 'attached_documents']
  ].freeze

  has_rich_text :default_email_text

  has_one_attached :logo

  accepts_nested_attributes_for :users, :account_request

  include Geocodable

  filterrific(
    available_filters: [
      :search_name
    ]
  )

  scope :alphabetized, -> { order(:name) }
  scope :search_name, ->(query) { where('name ilike ?', "%#{query}%") }

  scope :is_active, -> {
    joins(:users)
      .where('users.last_sign_in_at > ?', 4.months.ago)
      .distinct
  }

  def assign_attributes_from_account_request(account_request)
    assign_attributes(
      name: account_request.organization_name,
      url: account_request.organization_website,
      email: account_request.email,
      account_request_id: account_request.id
    )

    self
  end

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

  def valid_items
    items.active.visible.map do |item|
      {
        id: item.id,
        partner_key: item.partner_key,
        name: item.name
      }
    end
  end

  def item_id_to_display_string_map
    valid_items.each_with_object({}) do |item, hash|
      hash[item[:id].to_i] = item[:name]
    end
  end

  def valid_items_for_select
    valid_items.map { |item| [item[:name], item[:id]] }.sort
  end

  def from_email
    return get_admin_email if email.blank?

    email
  end

  # re 2813 update annual report -- allowing an earliest reporting year will let us do system testing and staging for annual reports
  def earliest_reporting_year
    year = created_at.year
    if donations.any?
      year = [year, donations.minimum(:issued_at).year].min
    end

    if purchases.any?
      year = [year, purchases.minimum(:issued_at).year].min
    end
    if distributions.any?
      year = [year, distributions.minimum(:issued_at).year].min
    end
    year
  end

  private

  def correct_logo_mime_type
    if logo.attached? && !logo.content_type
                              .in?(%w(image/jpeg image/jpg image/pjpeg image/png image/x-png))
      self.logo = nil
      errors.add(:logo, "Must be a JPG or a PNG file")
    end
  end

  def some_request_type_enabled
    unless enable_child_based_requests? || enable_individual_requests || enable_quantity_based_requests
      errors.add(:enable_child_based_requests, "You must allow at least one request type (child-based, individual, or quantity-based)")
      errors.add(:enable_individual_requests, "You must allow at least one request type (child-based, individual, or quantity-based)")
      errors.add(:enable_quantity_based_requests, "You must allow at least one request type (child-based, individual, or quantity-based)")
    end
  end

  def get_admin_email
    User.with_role(Role::ORG_ADMIN, self).sample.email
  end

  def logo_size_check
    errors.add(:logo, 'File size is greater than 1 MB') if logo.byte_size > 1.megabytes
  end
end
