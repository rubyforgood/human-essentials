# == Schema Information
#
# Table name: events
#
#  id              :bigint           not null, primary key
#  data            :jsonb
#  event_time      :datetime         not null
#  type            :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :bigint
#
class Event < ApplicationRecord
  scope :for_organization, ->(organization_id) { where(organization_id: organization_id).order(:event_time) }
end
