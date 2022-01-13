class Admin::HelpController < ApplicationController
  def help
    @bank_questions = Question.questions_for_banks(Question.all)
    @partner_questions = Question.questions_for_partners
  end
end
