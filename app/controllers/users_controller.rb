class UsersController < ApplicationController
  def index
    @users = current_organization.users
  end

  def new
    @user = User.new
  end

  def create
    org = Organization.find_by(short_name: params[:organization_id])
    @user = org.users.new(user_params)
    if @user.save
      @user.invite!(@user)
      redirect_to users_path, notice: "Created a new user!"
    else
      flash[:error] = "Failed to create user"
      render "users/new"
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end
end
