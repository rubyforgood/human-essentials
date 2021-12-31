class Admin::ArticlesController < ApplicationController

  def new
    @article = Article.new
  end

  def create
    @article = Article.create(article_params)
    redirect_to admin_dashboard_path
  end

  private

  def article_params
    params.require(:article).permit(:question, :for_partners, :for_organizations)
  end

end
