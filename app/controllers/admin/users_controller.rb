# [Super Admin] This is for administrating users at a global level. We can create, view, modify, etc.
class Admin::UsersController < AdminController
  before_action :load_organizations, only: %i[new create edit update]
  before_action :user_params, only: %i[create update]

  def index
    @filterrific = initialize_filterrific(
      User.includes(:organization).alphabetized,
      params[:filterrific],
      available_filters: [:search_name, :search_email]
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
      redirect_back(fallback_location: edit_admin_user_path)
    end
  end

  def new
    @user = User.new
  end

  def edit
    @user = User.find_by(id: params[:id])
    @resources = Role.resources_for_select
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

  def resource_ids
    klass = case params[:resource_type]
    when "org_admin", "org_user"
      Organization
    when "partner"
      Partner
    else
      raise "Unknown resource type #{params[:resource_type]}"
    end

    objects = klass.where("name LIKE ?", "%#{params[:q]}%").select(:id, :name)
    object_json = objects.map do |obj|
      {
        id: obj.id,
        text: obj.name
      }
    end
    render json: { results: object_json }
  end

  def add_role
    begin
      AddRoleService.call(user_id: params[:user_id],
        resource_type: params[:resource_type],
        resource_id: params[:resource_id])
    rescue => e
      redirect_back(fallback_location: admin_users_path, alert: e.message)
      return
    end
    redirect_back(fallback_location: admin_users_path, notice: "Role added!")
  end

  def remove_role
    RemoveRoleService.call(user_id: params[:user_id], role_id: params[:role_id])
    redirect_back(fallback_location: admin_users_path, notice: "Role removed!")
  rescue => e
    redirect_back(fallback_location: admin_users_path, alert: e.message)
  end

  private

  def user_params
    organization_id = params[:user][:organization_id]

    raise "Please select an organization for the user." if organization_id.blank?

    user_params = params.require(:user).permit(:name, :organization_id, :email, :password, :password_confirmation)
    user_params[:organization_role_join_attributes] = { role_id: updated_role_id(organization_id) }

    user_params
  rescue => e
    redirect_back(fallback_location: edit_admin_user_path, error: e.message)
  end

  def updated_role_id(organization_id)
    user_role_title = Role::TITLES[Role::ORG_USER]
    user_role_type = Role::ORG_USER

    role = Role.find_by(resource_type: user_role_title, resource_id: organization_id, name: user_role_type)

    role&.id || raise("Error finding a role within the provided organization")
  end

  def load_organizations
    @organizations = Organization.all.alphabetized
  end
end
