# == Schema Information
#
# Table name: partner_groups
#
#  id              :bigint           not null, primary key
#  name            :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :bigint
#
class PartnerGroup < ApplicationRecord
  belongs_to :organization
  has_many :partners, dependent: :nullify
  has_and_belongs_to_many :item_categories

  validates :organization, presence: true
  validates :name, presence: true, uniqueness: { scope: :organization }
end
