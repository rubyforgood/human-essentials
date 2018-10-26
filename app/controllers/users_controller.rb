class UsersController < ApplicationController
  def index
    @users = current_organization.users
  end
end
