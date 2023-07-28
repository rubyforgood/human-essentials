# == Schema Information
#
# Table name: kit_allocations
#
#  id                  :bigint           not null, primary key
#  kit_allocation_type :enum             default("inventory_in"), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  kit_id              :bigint           not null
#  organization_id     :bigint           not null
#  storage_location_id :bigint           not null
#
class KitAllocation < ApplicationRecord
  has_paper_trail
  include Itemizable
  belongs_to :storage_location
end
