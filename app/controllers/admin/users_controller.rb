# [Super Admin] This is for administrating users at a global level. We can create, view, modify, etc.
class Admin::UsersController < AdminController
  before_action :load_organizations, only: %i[create edit update]
  before_action :user_params, only: %i[create update]

  def index
    @filterrific = initialize_filterrific(
      User.includes(roles: :resource).alphabetized,
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
  end

  def create
    @user = User.new(user_params)
    validate_role_resource_params
    klass = Role::TITLE_TO_RESOURCE[params[:resource_type].to_sym]
    resource = klass&.find(params[:resource_id])
    UserInviteService.invite(
      name: user_params[:name],
      email: user_params[:email],
      roles: [params[:resource_type].to_sym],
      resource: resource
    )
    flash[:notice] = "Created a new user!"
    redirect_to admin_users_path
  rescue => e
    flash.now[:error] = "Failed to create user: #{e}"
    render :new
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
    params.require(:user).permit(:name, :email)
  end

  def validate_role_resource_params
    raise "Please select a role for the user." if params[:resource_type].blank?
    raise "Please select an associated resource for the role." if !Role::ROLES_WITHOUT_RESOURCE.map(&:to_s).include?(params[:resource_type]) && params[:resource_id].blank?
  end

  def load_organizations
    @organizations = Organization.all.alphabetized
  end
end
