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
require 'rails_helper'

RSpec.describe Article, type: :model do
  describe "#articles_for_partners" do
    it "should filter out articles meant for organizations" do
      article_1 = build(:article)
      article_1.update_attribute(:for_partners, false)
      article_1.update_attribute(:for_organizations, true)

      article_2 = build(:article)
      article_2.update_attribute(:for_partners, true)
      article_2.update_attribute(:for_organizations, false)

      article_3 = build(:article)
      article_3.update_attribute(:for_partners, true)
      article_3.update_attribute(:for_organizations, true)
      
      articles = [article_1, article_2, article_3]
      partner_articles = Article.articles_for_partners

      expect(partner_articles.count).to eq 2
      expect(partner_articles.first.for_partners).to eq true
      expect(partner_articles.last.for_partners).to eq true
    end
  end
end
