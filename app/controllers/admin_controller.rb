class AdminController < ApplicationController
  before_action :require_admin
  layout "admin"

  def require_admin
    verboten! unless current_user.super_admin?
  end

  def dashboard; end
end