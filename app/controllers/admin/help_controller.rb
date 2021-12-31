class Admin::HelpController < ApplicationController

  def help
    @organization_articles = Article.all.select{ |article| article.for_organizations == true }
    @partner_articles = Article.all.select{ |article| article.for_partners == true }
  end

end
