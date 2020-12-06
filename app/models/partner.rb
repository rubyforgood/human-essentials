# == Schema Information
#
# Table name: partners
#
#  id              :integer          not null, primary key
#  email           :string
#  name            :string
#  notes           :text
#  quota           :integer
#  send_reminders  :boolean          default(FALSE), not null
#  status          :integer          default(0)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :integer
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

  # better to extract this outside of the model
  def self.import_csv(csv, organization_id)
    csv.each do |row|
      hash_rows = Hash[row.to_hash.map { |k, v| [k.downcase, v] }]
      loc = Partner.new(hash_rows)
      loc.organization_id = organization_id
      loc.save
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
      contact_person[:phone] || contact_person[:mobile],
      contact_person[:email]
    ]
  end

  def self.generate_distributions_csv(distributions)
    rows = Exports::ExportPartnerDistributionsService.new(distributions).call
    CSV.generate(headers: true) do |csv|
      rows.each { |row| csv << row }
    end
  end

  def register_on_partnerbase
    UpdateDiaperPartnerJob.perform_now(id)
  end

  def add_user_on_partnerbase(options = {})
    AddDiaperPartnerJob.perform_now(id, options)
  end

  def partnerbase_partner
    @partnerbase_partner ||= Partnerbase::Partner.find(id) if id
  end

  def contact_person
    if partnerbase_partner&.agency
      partnerbase_partner.agency.fetch(:contact_person)
    else
      {}
    end
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
