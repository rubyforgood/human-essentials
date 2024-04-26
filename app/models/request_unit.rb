# == Schema Information
#
# Table name: request_units
#
#  id              :bigint           not null, primary key
#  name            :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :bigint
#
class RequestUnit < ApplicationRecord
  belongs_to :organization
end
