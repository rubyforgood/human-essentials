# == Schema Information
#
# Table name: events
#
#  id              :bigint           not null, primary key
#  data            :jsonb
#  event_time      :datetime         not null
#  eventable_type  :string
#  type            :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  eventable_id    :bigint
#  organization_id :bigint
#
class Event < ApplicationRecord
  scope :for_organization, ->(organization_id) { where(organization_id: organization_id).order(:event_time) }

  serialize :data, EventTypes::StructCoder.new(EventTypes::InventoryPayload)

  belongs_to :eventable, polymorphic: true
end
