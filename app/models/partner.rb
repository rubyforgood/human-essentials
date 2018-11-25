# == Schema Information
#
# Table name: partners
#
#  id              :bigint(8)        not null, primary key
#  name            :string
#  email           :string
#  created_at      :datetime
#  updated_at      :datetime
#  organization_id :integer
#  status          :string
#

class Partner < ApplicationRecord
  require "csv"

  belongs_to :organization
  has_many :distributions

  validates :organization, presence: true
  validates :name, :email, presence: true, uniqueness: true
  validates :email, format: { with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i, on: :create }

  scope :for_csv_export, ->(organization) {
    where(organization: organization)
      .order(:name)
  }

  # better to extract this outside of the model
  def self.import_csv(data, organization_id)
    CSV.parse(data, headers: true) do |row|
      hash_rows = Hash[row.to_hash.map { |k, v| [k.downcase, v] }]
      loc = Partner.new(hash_rows)
      loc.organization_id = organization_id
      loc.save!
    end
  end

  def self.csv_export_headers
    %w{Name Email}
  end

  def csv_export_attributes
    [name, email]
  end
end
