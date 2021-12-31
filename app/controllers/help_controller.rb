class HelpController < ApplicationController

  def show
    @articles = Article.all.select{ |article| article.for_organizations == true }
  end

end
