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
  require 'csv'

  belongs_to :organization
  has_many :distributions

  validates :organization, presence: true
  validates :name, :email, presence: true, uniqueness: true
  validates_format_of :email, :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i, :on => :create

  include DiaperPartnerClient
  after_create :update_diaper_partner

  def self.import_csv(filename,organization)
    CSV.parse(filename, :headers => true) do |row|
      loc = Partner.new(row.to_hash)
      loc.organization_id = organization
      loc.save!
    end
  end

  private

  def update_diaper_partner
    DiaperPartnerClient.post "/partners", attributes
  end
end
