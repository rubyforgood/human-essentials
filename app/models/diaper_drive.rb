# == Schema Information
#
# Table name: diaper_drives
#
#  id         :bigint(8)        not null, primary key
#  name       :string
#  start_date :date
#  end_date   :date
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class DiaperDrive < ApplicationRecord
  has_many :donations, dependent: :nullify
  validates :name, presence:
    { message: "A name must be chosen." }
  validates :start_date, presence:
    { message: "Please enter a start date." }
end
