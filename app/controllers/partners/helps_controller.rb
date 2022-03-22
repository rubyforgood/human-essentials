module Partners
  class HelpsController < BaseController
    layout 'partners/application'

    def show
      @filterrific = initialize_filterrific(
        Question.for_partners,
        params[:filterrific]
      ) || return

      @partner_questions = @filterrific.find.page(params[:page])

      respond_to do |format|
        format.html
        format.js
      end
    end
  end
end
