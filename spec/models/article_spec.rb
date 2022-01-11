# == Schema Information
#
# Table name: articles
#
#  id           :bigint           not null, primary key
#  for_banks    :boolean
#  for_partners :boolean
#  question     :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
require 'rails_helper'

RSpec.describe Article, type: :model do
  describe "#articles_for_partners" do
    it "should filter out articles that aren't meant for partners" do
      article_1 = build(:article)
      article_1.update(for_partners: false)
      article_1.update(for_banks: true)

      article_2 = build(:article)
      article_2.update(for_partners: true)
      article_2.update(for_banks: false)

      article_3 = build(:article)
      article_3.update(for_partners: true)
      article_3.update(for_banks: true)

      partner_articles = Article.articles_for_partners

      expect(partner_articles.count).to eq 2
      expect(partner_articles.first.for_partners).to eq true
      expect(partner_articles.last.for_partners).to eq true
    end
  end

  describe "#articles_for_banks" do
    it "should filter out articles that aren't meant for banks" do
      article_1 = build(:article)
      article_1.update(for_partners: false)
      article_1.update(for_banks: true)

      article_2 = build(:article)
      article_2.update(for_partners: true)
      article_2.update(for_banks: false)

      article_3 = build(:article)
      article_3.update(for_partners: true)
      article_3.update(for_banks: true)

      bank_articles = Article.articles_for_banks(Article.all)

      expect(bank_articles.count).to eq 2
      expect(bank_articles.first.for_banks).to eq true
      expect(bank_articles.last.for_banks).to eq true
    end
  end
end
