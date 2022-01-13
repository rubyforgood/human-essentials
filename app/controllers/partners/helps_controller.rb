module Partners
  class HelpsController < BaseController
    layout 'partners/application'

    def show
      @partner_questions = Question.questions_for_partners
    end
  end
end
