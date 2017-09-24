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
  require 'csv'

	belongs_to :organization
	
	validates :name, :address, :organization, presence: true
   
	has_many :donations
	
  def self.import_csv(filename,organization)
    CSV.parse(filename, :headers => true) do |row|
      loc = DropoffLocation.new(row.to_hash)
      loc.organization_id = organization
      loc.save!
    end
  end
end
