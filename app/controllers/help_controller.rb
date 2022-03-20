class HelpController < ApplicationController
  def show
    @filterrific = initialize_filterrific(
      Question.for_banks,
      params[:filterrific]
    ) || return

    @bank_questions = @filterrific.find.page(params[:page])

    respond_to do |format|
      format.html
      format.js
    end
  end
end
