class Admin::UsersController < AdminController
  before_action :load_organizations, only: %i[new create]

  def index
    @users = User.all
  end

  def update; end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    if @user.save
      @user.invite!(@user)
      redirect_to admin_users_path, notice: "Created a new user!"
    else
      flash[:error] = "Failed to create user"
      render "admin/users/new"
    end
  end

  def destroy
    @user = User.find_by(id: params[:id])
    if @user.present?
      @user.destroy
      redirect_to admin_users_path, notice: "Deleted that user"
    else
      redirect_to admin_users_path, flash: { error: "Couldn't find that user, sorry" }
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :organization_id, :email, :password, :password_confirmation)
  end

  def load_organizations
    @organizations = Organization.all
  end
end
