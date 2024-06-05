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
  # This validation prevent duplicates except when creating two units of the same name at the same time (on the organization update page)
  validates :name, uniqueness: {scope: :organization}
end
