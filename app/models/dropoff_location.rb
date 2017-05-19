# == Schema Information
#
# Table name: dropoff_locations
#
#  id              :integer          not null, primary key
#  name            :string
#  address         :string
#  created_at      :datetime
#  updated_at      :datetime
#  organization_id :integer
#

class DropoffLocation < ApplicationRecord
	belongs_to :organization
	
	validates :name, :address, :organization, presence: true
   
	has_many :donations

end
