# Provides scope-limited access to viewing the data of other users
class UsersController < ApplicationController
  def index
    @users = current_organization.users
  end

  def new
    @user = User.new
  end
end
