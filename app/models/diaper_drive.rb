# == Schema Information
#
# Table name: diaper_drives
#
#  id              :bigint           not null, primary key
#  end_date        :date
#  name            :string
#  start_date      :date
#  virtual         :boolean          default(FALSE), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :bigint
#

class DiaperDrive < ApplicationRecord
  belongs_to :organization, optional: true
  include Filterable

  scope :by_name, ->(name_filter) { where(name: name_filter) }

  scope :within_date_range, ->(search_range) {
    search_dates = search_date_range(search_range)
    where('end_date >= ? AND start_date <= ?', search_dates[:start_date], search_dates[:end_date])
  }

  has_many :donations, dependent: :nullify
  validates :name, presence:
    { message: "A name must be chosen." }
  validates :start_date, presence:
    { message: "Please enter a start date." }
  scope :alphabetized, -> { order(:name) }

  validate :end_date_is_bigger_of_end_date

  def end_date_is_bigger_of_end_date
    return if start_date.nil? || end_date.nil?

    if end_date < start_date
      errors.add(:end_date, 'End date must be after the start date')
    end
  end

  def donation_quantity
    donations.joins(:line_items).sum('line_items.quantity')
  end

  def distinct_items
    donations.joins(:items).distinct(:item_id).count
  end

  def in_kind_value
    donations.sum(&:value_per_itemizable)
  end

  def donation_source_view
    "#{name} (diaper drive)"
  end

  def self.search_date_range(dates)
    dates = dates.split(" - ")
    @search_date_range = { start_date: dates[0], end_date: dates[1] }
  end
end
