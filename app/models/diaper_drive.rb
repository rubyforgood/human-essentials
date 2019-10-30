# == Schema Information
#
# Table name: diaper_drives
#
#  id         :bigint           not null, primary key
#  end_date   :date
#  name       :string
#  start_date :date
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class DiaperDrive < ApplicationRecord
  include Filterable

  scope :by_name, ->(name_filter) { where(name: name_filter) }

  scope :within_date_rage, ->(search_range) {
    search_dates = search_date_range(search_range)
    where('end_date >= ? AND start_date <= ?', search_dates[:start_date], search_dates[:end_date])
  }

  has_many :donations, dependent: :nullify
  validates :name, presence:
    { message: "A name must be chosen." }
  validates :start_date, presence:
    { message: "Please enter a start date." }

  def self.search_date_range(dates)
    dates = dates.split(" - ")
    @search_date_range = { start_date: dates[0], end_date: dates[1] }
  end
end
