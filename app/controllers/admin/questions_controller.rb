class Admin::QuestionsController < ApplicationController
  def index
    @bank_questions = Question.questions_for_banks(Question.all)
    @partner_questions = Question.questions_for_partners
  end

  def new
    @question = Question.new
  end
 
  def create
    @question = Question.create(question_params)
    if @question.valid?
      redirect_to admin_questions_path
    else
      flash[:error] = "Failed to create question."
      render :new
    end
  end

  def edit
    @question = current_question
  end

  def update
    @question = current_question
    @question.update(question_params)
    if @question.valid?
      redirect_to admin_questions_path
    else
      flash[:error] = "Failed to create question."
      render :edit
    end
  end

  def destroy
    @question = current_question
    @question.destroy
    redirect_to admin_questions_path
  end

  private

  def current_question
    @current_question ||= Question.find(params[:id])
  end

  def question_params
    params.require(:question).permit(:title, :for_partners, :for_banks, :content)
  end
end
