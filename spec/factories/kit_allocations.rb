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
FactoryBot.define do
  factory :kit_allocation do
    storage_location { StorageLocation.try(:first) || create(:storage_location) }
    kit_id { Kit.try(:first)&.id || create(:kit).id }
    organization_id { storage_location.organization_id }

    after(:build) do |instance|
      kit = Kit.find(instance.kit_id)
      kit.update(organization_id: instance.organization_id)
    end
  end
end
