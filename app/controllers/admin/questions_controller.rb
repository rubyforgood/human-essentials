class Admin::QuestionsController < AdminController
  def index
    @bank_questions = Question.for_banks
    @partner_questions = Question.for_partners
  end

  def new
    @question = Question.new
  end

  def create
    @question = Question.create(question_params)
    if @question.valid?
      redirect_to admin_questions_path
    else
      flash[:error] = "Failed to create question. #{error_message_for_answer(@question.errors)}"
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
      flash[:error] = "Failed to update question. #{error_message_for_answer(@question.errors)}"
      render :edit
    end
  end

  def destroy
    @question = current_question
    @question.destroy
    redirect_to admin_questions_path
  end

  private

  def error_message_for_answer(errors)
    "Answer can't be blank." if !errors[:answer].empty?
  end

  def current_question
    @current_question ||= Question.find(params[:id])
  end

  def question_params
    params.require(:question).permit(:title, :for_partners, :for_banks, :answer)
  end
end
