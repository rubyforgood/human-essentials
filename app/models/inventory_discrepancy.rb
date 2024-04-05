# == Schema Information
#
# Table name: inventory_discrepancies
#
#  id              :bigint           not null, primary key
#  diff            :json
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  event_id        :bigint           not null
#  organization_id :bigint           not null
#
class InventoryDiscrepancy < ApplicationRecord
  belongs_to :event
  belongs_to :organization
end
