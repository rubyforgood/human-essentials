class Admin::QuestionsController < AdminController
  # Migrated to the Ruby for Good design system (ADR 0011).
  layout "essentials_app"

  def index
    @bank_questions = Question.all
  end

  def new
    @question = Question.new
  end

  # No flash on failure: @question carries its errors, so the form shows each one beside its own
  # field and the summary above lists them. The flash that used to be here called
  # `@question.punctuate(...)`, a method that exists nowhere in the app, so every invalid
  # submission raised NoMethodError and returned a 500 instead of the form.
  def create
    @question = Question.create(question_params)
    if @question.save
      redirect_to admin_questions_path
    else
      render :new
    end
  end

  def edit
    @question = current_question
  end

  def update
    @question = current_question
    if @question.update(question_params)
      redirect_to admin_questions_path
    else
      render :edit
    end
  end

  def destroy
    @question = current_question
    flash[:error] = "Failed to delete question." if !@question.destroy
    redirect_to admin_questions_path
  end

  private

  def current_question
    @current_question ||= Question.find(params[:id])
  end

  def question_params
    params.require(:question).permit(:title, :answer)
  end
end
