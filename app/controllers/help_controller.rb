class HelpController < ApplicationController
  def show
    @bank_articles = search(params[:keyword])
  end

  def search(keyword)
    if keyword.present?
      search_results = Article.where("question ILIKE ?", "%#{keyword}%")
      Article.articles_for_banks(search_results)
    else
      Article.articles_for_banks(Article.all)
    end
  end
end
