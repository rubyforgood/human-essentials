class Admin::HelpController < ApplicationController
  def help
    @organization_articles = Article.articles_for_organizations(Article.all)
    @partner_articles = Article.articles_for_partners
  end
end
