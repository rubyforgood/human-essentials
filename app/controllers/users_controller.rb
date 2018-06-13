class UsersController < ApplicationController
  def index
    @users = current_organization.users
  end

  def update; end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params.merge(organization_id: current_organization.id))

    if @user.save
      @user.invite!(@user)
      redirect_to users_path, notice: "Created a new user!"
    else
      flash[:error] = "Failed to create user"
      render :new
    end
  end

  def destroy
    @user = current_organization.users.find_by(id: params[:id])
    if @user.present?
      @user.destroy
      redirect_to users_path, notice: "Deleted that user"
    else
      redirect_to users_path, flash: { error: "Couldn't find that user, sorry" }
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end
end
