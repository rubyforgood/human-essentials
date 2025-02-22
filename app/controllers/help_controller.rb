class HelpController < ApplicationController
  def show
    @filterrific = initialize_filterrific(
      Question.all,
      params[:filterrific]
    ) || return

    @bank_questions = @filterrific.find

    respond_to do |format|
      format.html
      format.js
    end
  end
end
