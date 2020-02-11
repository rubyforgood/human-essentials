# Provides scope-limited access to viewing the data of other users
class UsersController < ApplicationController
  def index
    @users = current_organization.users
  end
end
