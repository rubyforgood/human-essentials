# == Schema Information
#
# Table name: partners
#
#  id              :integer          not null, primary key
#  email           :string
#  name            :string
#  send_reminders  :boolean          default(FALSE), not null
#  status          :integer          default("uninvited")
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :integer
#

class Partner < ApplicationRecord
  require "csv"

  enum status: { uninvited: 0, invited: 1, awaiting_review: 2, approved: 3, error: 4, recertification_required: 5, deactivated: 6 }

  belongs_to :organization
  has_many :distributions, dependent: :destroy
  has_many :requests, dependent: :destroy

  validates :organization, presence: true
  validates :name, presence: true, uniqueness: { scope: :organization }

  validates :email, presence: true,
                    uniqueness: true,
                    format: { with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i, on: :create }

  scope :for_csv_export, ->(organization) {
    where(organization: organization)
      .order(:name)
  }

  scope :alphabetized, -> { order(:name) }

  include Filterable
  scope :by_status, ->(status) {
    where(status: status.to_sym)
  }

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
    %w{Name Email}
  end

  def csv_export_attributes
    [name, email]
  end

  def register_on_partnerbase
    UpdateDiaperPartnerJob.perform_now(id)
  end

  def add_user_on_partnerbase(options = {})
    AddDiaperPartnerJob.perform_now(id, options)
  end

  def quantity_year_to_date
    distributions
      .includes(:line_items)
      .where("line_items.created_at > ?", Time.zone.today.beginning_of_year)
      .references(:line_items).map(&:line_items).flatten.sum(&:quantity)
  end
end
