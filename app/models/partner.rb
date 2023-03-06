# == Schema Information
#
# Table name: partners
#
#  id                          :integer          not null, primary key
#  email                       :string
#  name                        :string
#  notes                       :text
#  quota                       :integer
#  send_reminders              :boolean          default(FALSE), not null
#  status                      :integer          default("uninvited")
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  default_storage_location_id :bigint
#  organization_id             :integer
#  partner_group_id            :bigint
#

class Partner < ApplicationRecord
  resourcify
  require "csv"

  ALLOWED_MIME_TYPES = [
    "application/pdf",
    "application/msword",
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
  ].freeze

  enum status: { uninvited: 0, invited: 1, awaiting_review: 2, approved: 3, error: 4, recertification_required: 5, deactivated: 6 }

  belongs_to :organization
  belongs_to :partner_group, optional: true
  has_many :item_categories, through: :partner_group
  has_many :requestable_items, through: :item_categories, source: :items
  has_one :profile, class_name: 'Partners::Profile', dependent: :destroy

  has_many :distributions, dependent: :destroy
  has_many :requests, dependent: :destroy, class_name: '::Request'
  has_many :users, through: :roles, class_name: '::User', dependent: :destroy
  has_many :families, dependent: :destroy, class_name: 'Partners::Family'
  has_many :children, through: :families, class_name: 'Partners::Child'
  has_many :authorized_family_members, through: :families, class_name: 'Partners::AuthorizedFamilyMember'

  has_many_attached :documents

  validates :organization, presence: true
  validates :name, presence: true, uniqueness: { scope: :organization }

  validates :email, presence: true, uniqueness: { case_sensitive: false },
    format: { with: URI::MailTo::EMAIL_REGEXP, on: :create }

  validates :quota, numericality: true, allow_blank: true

  validate :correct_document_mime_type

  before_save { email&.downcase! }
  before_update :invite_new_partner, if: :should_invite_because_email_changed?

  scope :for_csv_export, ->(organization, *) {
    where(organization: organization)
      .order(:name)
  }

  scope :alphabetized, -> { order(:name) }
  scope :active, -> { where.not(status: :deactivated) }

  include Filterable
  include Exportable
  scope :by_status, ->(status) {
    where(status: status.to_sym)
  }

  AGENCY_TYPES = {
    "CAREER" => "Career technical training",
    "ABUSE" => "Child abuse resource center",
    "CHURCH" => "Church outreach ministry",
    "CDC" => "Community development corporation",
    "HEALTH" => "Community health program",
    "OUTREACH" => "Community outreach services",
    "CRISIS" => "Crisis/Disaster services",
    "DISAB" => "Developmental disabilities program",
    "DOMV" => "Domestic violence shelter",
    "CHILD" => "Early childhood services",
    "EDU" => "Education program",
    "FAMILY" => "Family resource center",
    "FOOD" => "Food bank/pantry",
    "GOVT" => "Government Agency/Affiliate",
    "HEADSTART" => "Head Start/Early Head Start",
    "HOMEVISIT" => "Home visits",
    "HOMELESS" => "Homeless resource center",
    "INFPAN" => "Infant/Child Pantry/Closet",
    "PREG" => "Pregnancy resource center",
    "REF" => "Refugee resource center",
    "TREAT" => "Treatment clinic",
    "WIC" => "Women, Infants and Children",
    "OTHER" => "Other"
  }.freeze

  ALL_PARTIALS = %w[
    media_information
    agency_stability
    organizational_capacity
    sources_of_funding
    population_served
    executive_director
    diaper_pick_up_person
    agency_distribution_information
    attached_documents
  ].freeze

  # @return [String]
  def display_status
    case status
    when :awaiting_review
      'Submitted'
    when :uninvited
      'Pending'
    when :approved
      'Verified'
    else
      status.titleize
    end
  end

  def primary_user
    users.order('created_at ASC').first
  end

  # @return [Boolean]
  def deletable?
    uninvited? &&
      distributions.none? &&
      requests.none? &&
      users&.none?
  end

  def approvable?
    invited? || awaiting_review?
  end

  # better to extract this outside of the model
  def self.import_csv(csv, organization_id)
    organization = Organization.find(organization_id)

    csv.each do |row|
      hash_rows = Hash[row.to_hash.map { |k, v| [k.downcase, v] }]

      svc = PartnerCreateService.new(organization: organization, partner_attrs: hash_rows)
      svc.call
    end
  end

  def self.csv_export_headers
    [
      "Agency Name",
      "Agency Email",
      "Contact Name",
      "Contact Phone",
      "Contact Email"
    ]
  end

  def csv_export_attributes
    [
      name,
      email,
      contact_person[:name],
      contact_person[:phone],
      contact_person[:email]
    ]
  end

  def contact_person
    return @contact_person if @contact_person

    return {} if profile.blank?

    @contact_person = {
      name: profile.primary_contact_name,
      email: profile.primary_contact_email,
      phone: profile.primary_contact_phone ||
             profile.primary_contact_mobile
    }
  end

  def partials_to_show
    organization.partner_form_fields.presence || ALL_PARTIALS
  end

  def quantity_year_to_date
    distributions
      .includes(:line_items)
      .where('distributions.issued_at >= ?', Time.zone.today.beginning_of_year)
      .references(:line_items).map(&:line_items).flatten.sum(&:quantity)
  end

  def impact_metrics
    {
      families_served: families_served_count,
      children_served: children_served_count,
      family_zipcodes: family_zipcodes_count,
      family_zipcodes_list: family_zipcodes_list
    }
  end

  private

  def families_served_count
    families.count
  end

  def children_served_count
    children.count
  end

  def family_zipcodes_count
    families.pluck(:guardian_zip_code).uniq.count
  end

  def family_zipcodes_list
    families.pluck(:guardian_zip_code).uniq
  end

  def correct_document_mime_type
    if documents.attached? && documents.any? { |doc| !doc.content_type.in?(ALLOWED_MIME_TYPES) }
      errors.add(:documents, "Must be a PDF or DOC file")
    end
  end

  def invite_new_partner
    UserInviteService.invite(email: email, roles: [Role::PARTNER], resource: self)
  end

  def should_invite_because_email_changed?
    email_changed? and (invited? or awaiting_review? or recertification_required? or approved?)
  end
end
