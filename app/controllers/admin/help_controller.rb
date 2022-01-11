class Admin::HelpController < ApplicationController
  def help
    @bank_articles = Article.articles_for_banks(Article.all)
    @partner_articles = Article.articles_for_partners
  end
end
