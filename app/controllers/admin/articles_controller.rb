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
    @article = current_article
  end

  def update
    @article = current_article
    @article.update(article_params)
    if @article.valid?
      redirect_to admin_help_path
    else
      flash[:error] = "Failed to create article."
      render :edit
    end
  end

  def destroy
    @article = current_article
    @article.destroy
    redirect_to admin_help_path
  end

  private

  def current_article
    @current_article ||= Article.find(params[:id])
  end

  def article_params
    params.require(:article).permit(:question, :for_partners, :for_banks, :content)
  end
end
