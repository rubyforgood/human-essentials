# == Schema Information
#
# Table name: dropoff_locations
#
#  id         :integer          not null, primary key
#  name       :string
#  address    :string
#  created_at :datetime
#  updated_at :datetime
#

class DropoffLocation < ApplicationRecord
    validates_presence_of :name
    validates_presence_of :address

	has_many :donations

end
