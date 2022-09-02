# [Super Admin] This is for administrating users at a global level. We can create, view, modify, etc.
class Admin::UsersController < AdminController
  before_action :load_organizations, only: %i[new create edit update]

  def index
    @users = User.includes(:organization).alphabetized.page(params[:page])
  end

  def update
    @user = User.find_by(id: params[:id])
    if @user.update(user_params)
      flash[:notice] = "#{@user.name} updated!"
      redirect_to admin_users_path
    else
      flash[:error] = "Something didn't work quite right -- try again?"
      render action: :edit
    end
  end

  def new
    @user = User.new
  end

  def edit
    @user = User.find_by(id: params[:id])
  end

  def create
    UserInviteService.invite(name: user_params[:name],
      email: user_params[:email],
      roles: %i[org_user],
      resource: Organization.find(user_params[:organization_id]))
    flash[:notice] = "Created a new user!"
    redirect_to admin_users_path
  rescue
    flash[:error] = "Failed to create user"
    render "admin/users/new"
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
    @organizations = Organization.all.alphabetized
  end
end
