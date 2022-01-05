# == Schema Information
#
# Table name: articles
#
#  id                :bigint           not null, primary key
#  for_organizations :boolean
#  for_partners      :boolean
#  question          :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
class Article < ApplicationRecord
  has_rich_text :content
  validates :question, presence: true
  validates :for_organizations, acceptance: true, unless: :for_partners
  validates :for_partners, acceptance: true, unless: :for_organizations
end
