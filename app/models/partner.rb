# == Schema Information
#
# Table name: partners
#
#  id               :integer          not null, primary key
#  email            :string
#  name             :string
#  notes            :text
#  quota            :integer
#  send_reminders   :boolean          default(FALSE), not null
#  status           :integer          default("uninvited")
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  organization_id  :integer
#  partner_group_id :bigint
#

class Partner < ApplicationRecord
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

  has_many :distributions, dependent: :destroy
  has_many :requests, dependent: :destroy

  has_many_attached :documents

  validates :organization, presence: true
  validates :name, presence: true, uniqueness: { scope: :organization }

  validates :email, presence: true,
                    uniqueness: true,
                    format: { with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i, on: :create }

  validates :quota, numericality: true, allow_blank: true

  validate :correct_document_mime_type

  scope :for_csv_export, ->(organization, *) {
    where(organization: organization)
      .order(:name)
  }

  scope :alphabetized, -> { order(:name) }

  include Filterable
  include Exportable
  scope :by_status, ->(status) {
    where(status: status.to_sym)
  }

  def deactivated?
    status == 'deactivated'
  end

  #
  # Returns the Partners::Partner record which is stored in
  # the partnerbase DB and contains mostly profile data of
  # the partner user.
  def profile
    @profile ||= ::Partners::Partner.find_by(diaper_partner_id: id)
  end

  #
  # Returns the primary Partners::User record which is the
  # first & main user associated to a partner agency.
  def primary_partner_user
    profile&.primary_user
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

  def meow
    partners = Partner.where.not(status: 'deactivated')
    users = partners.map(&:profile).map(&:users).flatten
    emails = users.map(&:email)
    partner_emails = emails.flatten

    user_emails = User.where(discarded_at: nil).pluck(:email)

    emails = [partner_emails + user_emails].flatten

    CSV.open("contact_emails.csv", "wb") do |csv|
      csv << ["Email Address"]
      emails.each do |email|
        csv << [email]
      end
    end
  end

  def contact_person
    return @contact_person if @contact_person

    return {} if profile.blank?

    @contact_person = {
      name: profile.program_contact_name,
      email: profile.program_contact_email,
      phone: profile.program_contact_phone ||
             profile.program_contact_mobile
    }
  end

  def quantity_year_to_date
    distributions
      .includes(:line_items)
      .where("line_items.created_at > ?", Time.zone.today.beginning_of_year)
      .references(:line_items).map(&:line_items).flatten.sum(&:quantity)
  end

  protected

  def correct_document_mime_type
    if documents.attached? && documents.any? { |doc| !doc.content_type.in?(ALLOWED_MIME_TYPES) }
      errors.add(:documents, "Must be a PDF or DOC file")
    end
  end
end
