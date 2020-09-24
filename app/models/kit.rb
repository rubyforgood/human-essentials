# == Schema Information
#
# Table name: kits
#
#  id              :bigint           not null, primary key
#  name            :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :integer
#
class Kit < ApplicationRecord
  include Itemizable

  belongs_to :organization
  validates :organization, presence: true
end
