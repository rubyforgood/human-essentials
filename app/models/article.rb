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
  validates :content, presence: true
  validates :question, presence: true
  validates :for_organizations, acceptance: { message: "and for partners can't both be unchecked" }, unless: :for_partners
  validates :for_partners, acceptance: { message: "and for organizations can't both be unchecked" }, unless: :for_organizations

  def self.articles_for_organizations(articles)
    articles.select { |article| article&.for_organizations }
  end

  def self.articles_for_partners
    Article.all.select { |article| article&.for_partners }
  end
end
