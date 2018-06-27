class AdminController < ApplicationController
  before_action :require_admin

  def require_admin
    unless current_user.is_superadmin?
       redirect_to root_path, flash: { error: "Access Denied. Only for SuperAdmin." }
    end
  end
end