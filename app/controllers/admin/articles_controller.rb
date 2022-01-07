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

  private

  def article_params
    params.require(:article).permit(:question, :for_partners, :for_organizations, :content)
  end
end
