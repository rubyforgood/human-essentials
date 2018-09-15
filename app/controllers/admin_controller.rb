class AdminController < ApplicationController
  before_action :require_admin

  def require_admin
    verboten! unless current_user.superadmin?
  end
end