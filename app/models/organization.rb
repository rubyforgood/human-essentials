# == Schema Information
#
# Table name: organizations
#
#  id                                       :integer          not null, primary key
#  city                                     :string
#  deadline_day                             :integer
#  default_storage_location                 :integer
#  distribute_monthly                       :boolean          default(FALSE), not null
#  email                                    :string
#  enable_child_based_requests              :boolean          default(TRUE), not null
#  enable_individual_requests               :boolean          default(TRUE), not null
#  enable_quantity_based_requests           :boolean          default(TRUE), not null
#  hide_package_column_on_receipt           :boolean          default(FALSE)
#  hide_value_columns_on_receipt            :boolean          default(FALSE)
#  include_in_kind_values_in_exported_files :boolean          default(FALSE), not null
#  intake_location                          :integer
#  invitation_text                          :text
#  latitude                                 :float
#  longitude                                :float
#  name                                     :string
#  one_step_partner_invite                  :boolean          default(FALSE), not null
#  partner_form_fields                      :text             default([]), is an Array
#  receive_email_on_requests                :boolean          default(FALSE), not null
#  reminder_day                             :integer
#  repackage_essentials                     :boolean          default(FALSE), not null
#  signature_for_distribution_pdf           :boolean          default(FALSE)
#  state                                    :string
#  street                                   :string
#  url                                      :string
#  ytd_on_distribution_printout             :boolean          default(TRUE), not null
#  zipcode                                  :string
#  created_at                               :datetime         not null
#  updated_at                               :datetime         not null
#  account_request_id                       :integer
#  ndbn_member_id                           :bigint
#

class Organization < ApplicationRecord
  has_paper_trail
  resourcify

  DIAPER_APP_LOGO = Rails.public_path.join("img", "humanessentials_logo.png")

  include Deadlinable

  # TODO: remove once migration "20250504183911_remove_short_name_from_organizations" has run in production
  self.ignored_columns += ["short_name"]

  validates :name, presence: true
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
    has_many :items
    has_many :item_categories
    has_many :manufacturers
    has_many :partners
    has_many :partner_groups
    has_many :purchases
    has_many :requests
    has_many :storage_locations
    has_many :tags
    has_many :product_drive_tags, -> { by_type("ProductDrive") },
      class_name: "Tag", inverse_of: false
    has_many :inventory_items, through: :storage_locations
    has_many :kits
    has_many :transfers
    has_many :users, -> { distinct }, through: :roles
    has_many :vendors
    has_many :request_units, class_name: 'Unit'
  end

  has_many :barcode_items, dependent: :destroy do
    def all
      unscope(where: :organization_id).where("barcode_items.organization_id = ? OR barcode_items.barcodeable_type = ?", proxy_association.owner.id, "BaseItem")
    end
  end
  has_many :distributions, dependent: :destroy do
    def upcoming
      this_week.scheduled.where(issued_at: Time.zone.today..)
    end
  end

  after_create do
    account_request&.update!(status: "admin_approved")
  end

  def flipper_id
    "Org:#{id}"
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
  has_rich_text :reminder_email_text

  has_one_attached :logo

  accepts_nested_attributes_for :users, :account_request, :request_units

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

  def partials_to_show
    partner_form_fields.presence || ALL_PARTIALS.map { |partial| partial[1] }
  end

  def self.seed_items(organization = Organization.all)
    base_items = BaseItem.without_kit.map(&:to_h)

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
      if e.to_s.match(/already exists/).present? && existing_item.other?
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

  def display_last_distribution_date
    distribution = distributions.order(issued_at: :desc).first
    distribution.nil? ? "No distributions" : distribution[:issued_at].strftime("%F")
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
