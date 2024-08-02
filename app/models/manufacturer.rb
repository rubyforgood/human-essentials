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

  def self.by_donation_count(count = 10, date_range = nil)
    # selects manufacturers that have donation qty > 0 in the provided date range
    # and sorts them by highest volume of donation
    manufacturers = select do |m|
      donation_volume = m.donations.joins(:line_items).where(issued_at: date_range).sum(:quantity)
      if donation_volume.positive?
        m.instance_variable_set(:@num_of_donations, donation_volume)
        m
      end
    end

    manufacturers.sort_by { |m| -m.instance_variable_get(:@num_of_donations) }.first(count)
  end

  private

  def exists_in_org?
    organization.manufacturers.where(name: name).exists?
  end
end
