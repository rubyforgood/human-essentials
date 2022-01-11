class Admin::ArticlesController < ApplicationController
  def new
    @article = Article.new
  end

  def create
    @article = Article.create(article_params)
    if @article.valid?
      redirect_to admin_help_path
    else
      flash[:error] = "Failed to create article."
      render :new
    end
  end

  def edit
    @article = Article.find(params[:id])
  end

  def update
    @article = Article.find(params[:id])
    @article.update(article_params)
    if @article.valid?
      redirect_to admin_help_path
    else
      flash[:error] = "Failed to create article."
      render :edit
    end
  end

  private

  def article_params
    params.require(:article).permit(:question, :for_partners, :for_banks, :content)
  end
end
