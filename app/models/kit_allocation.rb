# == Schema Information
#
# Table name: kit_allocations
#
#  id                  :bigint           not null, primary key
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  kit_id              :bigint           not null
#  organization_id     :bigint           not null
#  storage_location_id :bigint           not null
#
class KitAllocation < ApplicationRecord
  include Itemizable
  belongs_to :storage_location
end
