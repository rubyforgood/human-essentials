class HelpController < ApplicationController

  def show
    @organization_articles = Article.all.select{ |article| article.for_organizations == true }
  end

end
