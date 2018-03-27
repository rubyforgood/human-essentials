# == Schema Information
#
# Table name: partners
#
#  id              :integer          not null, primary key
#  name            :string
#  email           :string
#  created_at      :datetime
#  updated_at      :datetime
#  organization_id :integer
#

class Partner < ApplicationRecord
  require "csv"

  belongs_to :organization
  has_many :distributions

  validates :organization, presence: true
  validates :name, :email, presence: true, uniqueness: true
  validates :email, format: { with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i, on: :create }

  after_create :notify_diaper_partner

  def self.import_csv(filename, organization)
    CSV.parse(filename, headers: true) do |row|
      loc = Partner.new(row.to_hash)
      loc.organization_id = organization
      loc.save!
    end
  end

  private

  def notify_diaper_partner
    diaper_partner_url = ENV["DIAPER_PARTNER_URL"]
    return if diaper_partner_url.blank?

    uri = URI(diaper_partner_url + "/partners")
    request = Net::HTTP::Post.new uri
    request.set_form_data attributes

    Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request ApiAuth.sign!(request, "diaperbase", ENV["DIAPER_PARTNER_SECRET_KEY"])
    end
  end
end
