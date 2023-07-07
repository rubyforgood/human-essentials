# [Super Admin] This is for administrating users at a global level. We can create, view, modify, etc.
class Admin::UsersController < AdminController
  before_action :load_organizations, only: %i[new create edit update]

  def index
    @filterrific = initialize_filterrific(
      User.includes(:organization).alphabetized,
      params[:filterrific]
    ) || return
    @users = @filterrific.find.page(params[:page])

    respond_to do |format|
      format.html
      format.js
    end
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
      roles: [Role::ORG_USER],
      resource: Organization.find(user_params[:organization_id]))
    flash[:notice] = "Created a new user!"
    redirect_to admin_users_path
  rescue => e
    flash[:error] = "Failed to create user: #{e}"
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

  def remove_role
    user_role = UsersRole.find_by(user_id: params[:user_id], role_id: params[:role_id])
    if user_role
      user_role.destroy
      if user_role.role.name.to_sym == :org_user # they can't be an admin if they're not a user
        admin_role = Role.find_by(resource_id: user_role.role.resource_id, name: :org_admin)
        UsersRole.find_by(user_id: params[:user_id], role_id: admin_role.id)&.destroy
      end
      redirect_back(fallback_location: admin_users_path, notice: 'Role removed!')
    else
      redirect_back(fallback_location: admin_users_path, alert: 'Could not find role!')
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
