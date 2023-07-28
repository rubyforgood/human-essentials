# == Schema Information
#
# Table name: manufacturers
#
#  id              :bigint           not null, primary key
#  name            :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :bigint
#

class Manufacturer < ApplicationRecord
  has_paper_trail
  belongs_to :organization

  has_many :donations, inverse_of: :manufacturer, dependent: :destroy

  has_many :line_items, through: :donations

  validates :name, presence: true, uniqueness: { scope: :organization, message: 'Manufacturer already exists' }

  scope :alphabetized, -> { order(:name) }

  def volume
    # returns 0 instead of nil when Manufacturer exists without any donations
    donations.joins(:line_items).sum(:quantity)
  end

  def self.by_donation_count(count = 10)
    # selects manufacturers that have donation qty > 0
    # and sorts them by highest volume of donation
    select { |m| m.volume.positive? }.sort.reverse.first(count)
  end

  private

  def exists_in_org?
    organization.manufacturers.where(name: name).exists?
  end
end
