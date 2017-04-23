# == Schema Information
#
# Table name: partners
#
#  id         :integer          not null, primary key
#  name       :string
#  email      :string
#  created_at :datetime
#  updated_at :datetime
#

class Partner < ApplicationRecord
  has_many :tickets

  validates_presence_of :name
  validates_presence_of :email
end
