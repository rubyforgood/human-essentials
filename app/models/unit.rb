# == Schema Information
#
# Table name: units
#
#  id              :bigint           not null, primary key
#  name            :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :bigint
#
class Unit < ApplicationRecord
  belongs_to :organization
  validates :name, uniqueness: {scope: :organization}
end
