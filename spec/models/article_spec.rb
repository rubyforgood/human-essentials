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
    it "should filter out articles that aren't meant for partners" do
      article_1 = build(:article)
      article_1.update(for_partners: false)
      article_1.update(for_organizations: true)

      article_2 = build(:article)
      article_2.update(for_partners: true)
      article_2.update(for_organizations: false)

      article_3 = build(:article)
      article_3.update(for_partners: true)
      article_3.update(for_organizations: true)

      partner_articles = Article.articles_for_partners

      expect(partner_articles.count).to eq 2
      expect(partner_articles.first.for_partners).to eq true
      expect(partner_articles.last.for_partners).to eq true
    end
  end

  describe "#articles_for_organizations" do
    it "should filter out articles that aren't meant for organizations" do
      article_1 = build(:article)
      article_1.update(for_partners: false)
      article_1.update(for_organizations: true)

      article_2 = build(:article)
      article_2.update(for_partners: true)
      article_2.update(for_organizations: false)

      article_3 = build(:article)
      article_3.update(for_partners: true)
      article_3.update(for_organizations: true)

      organization_articles = Article.articles_for_organizations(Article.all)

      expect(organization_articles.count).to eq 2
      expect(organization_articles.first.for_organizations).to eq true
      expect(organization_articles.last.for_organizations).to eq true
    end
  end
end
