class HelpController < ApplicationController
  def show
    @bank_questions = search(params[:keyword])
  end

  def search(keyword)
    if keyword.present?
      search_results = Question.where("title ILIKE ?", "%#{keyword}%")
      Question.questions_for_banks(search_results)
    else
      Question.questions_for_banks(Question.all)
    end
  end
end
