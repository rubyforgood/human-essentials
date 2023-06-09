# == Schema Information
#
# Table name: kit_allocations
#
#  id                  :bigint           not null, primary key
#  kit_allocation_type :integer          default(0), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  kit_id              :bigint           not null
#  organization_id     :bigint           not null
#  storage_location_id :bigint           not null
#
class KitAllocation < ApplicationRecord
  include Itemizable
  belongs_to :storage_location
  enum kit_allocation_type: {inventory_in: 0, inventory_out: 1}
end
