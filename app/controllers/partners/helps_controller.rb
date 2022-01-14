module Partners
  class HelpsController < BaseController
    layout 'partners/application'

    def show
      @partner_questions = Question.for_partners
    end
  end
end
