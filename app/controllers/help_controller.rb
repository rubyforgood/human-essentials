class HelpController < ApplicationController
  # Migrated to the Ruby for Good design system (ADR 0011).
  layout "essentials_app"

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
