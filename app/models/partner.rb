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
  has_paper_trail
  resourcify
  require "csv"

  ALLOWED_MIME_TYPES = [
    "application/pdf",
    "application/msword",
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
  ].freeze

  # Status `4` (error) was removed for being obsolete but is intentionally skipped to preserve existing enum values.
  enum :status, { uninvited: 0, invited: 1, awaiting_review: 2, approved: 3, recertification_required: 5, deactivated: 6 }

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

  validates :name, presence: true, uniqueness: { scope: :organization }

  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }

  validates :quota, numericality: { greater_than_or_equal_to: 0 }, allow_blank: true

  validate :correct_document_mime_type

  validate :default_storage_location_belongs_to_organization

  before_save { email&.downcase! }
  before_create :default_send_reminders_to_false, if: :send_reminders_nil?
  before_update :invite_new_partner, if: :should_invite_because_email_changed?

  scope :alphabetized, -> { order(:name) }
  scope :active, -> { where.not(status: :deactivated) }

  include Filterable
  include Exportable
  scope :by_status, ->(status) {
    where(status: status.to_sym)
  }

  ALL_PARTIALS = Organization::ALL_PARTIALS.map { |partial| partial[1] }.freeze

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
    errors = []
    organization = Organization.find(organization_id)

    csv.each do |row|
      hash_rows = Hash[row.to_hash.map { |k, v| [k.downcase, v] }]

      svc = PartnerCreateService.new(organization: organization, partner_attrs: hash_rows)
      svc.call
      if svc.errors.present? && svc.partner.errors.blank?
        errors << "#{svc.partner.name}: #{svc.errors.full_messages.to_sentence}"
      elsif svc.errors.present?
        errors << "#{svc.partner.name}: #{svc.partner.errors.full_messages.to_sentence}"
      end
    end
    errors
  end

  def partials_to_show
    organization.partials_to_show
  end

  def quantity_year_to_date
    distributions
      .includes(:line_items)
      .where(distributions: { issued_at: Time.zone.today.beginning_of_year.. })
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

  def quota_exceeded?(total)
    quota.present? && total > quota
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

  def default_storage_location_belongs_to_organization
    location_ids = organization&.storage_locations&.pluck(:id)
    unless location_ids&.include?(default_storage_location_id) || default_storage_location_id.nil?
      errors.add(:default_storage_location_id, "The default storage location is not a storage location for this partner's organization")
    end
  end

  def correct_document_mime_type
    if documents.attached? && documents.any? { |doc| !doc.content_type.in?(ALLOWED_MIME_TYPES) }
      errors.add(:documents, "Must be a PDF or DOC file")
    end
  end

  def default_send_reminders_to_false
    self.send_reminders = false
  end

  def send_reminders_nil?
    send_reminders.nil?
  end

  def invite_new_partner
    UserInviteService.invite(email: email, roles: [Role::PARTNER], resource: self)
  end

  def should_invite_because_email_changed?
    email_changed? &&
      (
        invited? ||
        awaiting_review? ||
        recertification_required? ||
        approved?
      ) &&
      !partner_user_with_same_email_exist?
  end

  def partner_user_with_same_email_exist?
    User.exists?(email: email) && User.find_by(email: email).has_role?(Role::PARTNER, self)
  end
end
