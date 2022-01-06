module Partners
  class HelpsController < BaseController
    layout 'partners/application'

    def show
      @partner_articles = Article.articles_for_partners
    end
  end
end
