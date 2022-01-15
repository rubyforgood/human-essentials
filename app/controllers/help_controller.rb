class HelpController < ApplicationController
  def show
    @bank_questions = search(params[:keyword])
  end

  private

  def search(keyword)
    if keyword.present?
      Question.for_banks.where("title ILIKE ?", "%#{keyword}%")
    else
      Question.for_banks
    end
  end
end
