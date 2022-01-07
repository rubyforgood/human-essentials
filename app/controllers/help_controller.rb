class HelpController < ApplicationController
  def show
    @organization_articles = search(params[:keyword])
  end

  def search(keyword)
    if keyword.present?
      search_results = Article.where("question ILIKE ?", "%#{keyword}%")
      Article.articles_for_organizations(search_results)
    else
      Article.articles_for_organizations(Article.all)
    end
  end
end
