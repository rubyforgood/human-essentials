# == Schema Information
#
# Table name: kits
#
#  id              :bigint           not null, primary key
#  active          :boolean          default(TRUE)
#  name            :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :integer
#
class Kit < ApplicationRecord
  include Itemizable
  include Filterable

  belongs_to :organization

  scope :active, -> { where(active: true) }
  scope :alphabetized, -> { order(:name) }
  scope :by_partner_key, ->(key) { joins(:items).where(items: { partner_key: key }) }

  validates :organization, :name, presence: true
end
