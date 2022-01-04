module Partners
  class HelpsController < BaseController
    layout 'partners/application'

    def show
      @partner_articles = Article.all.select{ |article| article.for_partners == true }
    end
  end
end
