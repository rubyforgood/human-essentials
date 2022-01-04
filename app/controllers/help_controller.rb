class HelpController < ApplicationController

  def show
    @organization_articles = search(params[:keyword])
  end

  def search(keyword)
    if keyword.present?
      Article.where("question ILIKE ?", "%#{keyword}%")
    else
      Article.all.select{ |article| article.for_organizations == true }
    end
  end

end
