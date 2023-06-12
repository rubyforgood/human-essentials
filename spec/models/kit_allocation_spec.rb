# == Schema Information
#
# Table name: kit_allocations
#
#  id                  :bigint           not null, primary key
#  inventory           :enum             default("inventory_in"), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  kit_id              :bigint           not null
#  organization_id     :bigint           not null
#  storage_location_id :bigint           not null
#
require "rails_helper"

RSpec.describe KitAllocation, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
