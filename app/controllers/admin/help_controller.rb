class Admin::HelpController < ApplicationController
  
  def partners_help
    @articles = Article.all.select{ |article| article.for_partners == true }
  end

  def organizations_help
    @articles = Article.all.select{ |article| article.for_organizations == true }
  end

end
