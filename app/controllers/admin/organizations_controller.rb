# [Super Admin] This is for administrating organizations at a global level. We can create, view, modify, etc.
class Admin::OrganizationsController < AdminController
  def edit
    @organization = Organization.find(params[:id])
  end

  def update
    @organization = Organization.find(params[:id])

    if OrganizationUpdateService.update(@organization, organization_params)
      redirect_to admin_organizations_path, notice: "Updated organization!"
    else
      flash[:error] = @organization.errors.full_messages.join("\n")
      render :edit
    end
  end

  def index
    @filterrific = initialize_filterrific(
      Organization.alphabetized,
      params[:filterrific]
    ) || return

    @organizations = @filterrific.find.page(params[:page])

    respond_to do |format|
      format.html
      format.js
    end
  end

  def new
    @organization = Organization.new
    account_request = params[:token] && AccountRequest.get_by_identity_token(params[:token])

    @user = User.new
    return unless account_request

    if account_request.processed?
      flash[:error] = "The account request had already been processed and cannot be used again"
    else
      @organization.assign_attributes_from_account_request(account_request)
      @user.assign_attributes(email: account_request.email, name: account_request.name)
    end
  end

  def create
    @organization = Organization.new(organization_params)

    if @organization.save
      Organization.seed_items(@organization)
      @user = UserInviteService.invite(name: user_params[:name],
                                       email: user_params[:email],
                                       roles: [Role::ORG_USER, Role::ORG_ADMIN],
                                       resource: @organization)
      SnapshotEvent.publish(@organization) # need one to start with
      redirect_to admin_organizations_path, notice: "Organization added!"
    else
      flash[:error] = "Failed to create Organization."
      render :new
    end
  rescue => e
    flash[:error] = e
    render :new
  end

  def show
    @organization = Organization.find(params[:id])
    @header_link = admin_dashboard_path
  end

  def destroy
    @organization = Organization.find(params[:id])
    if @organization.destroy
      redirect_to admin_organizations_path, notice: "Organization deleted!"
    else
      redirect_to admin_organizations_path, alert: "Failed to delete Organization."
    end
  end

  private

  def organization_params
    params.require(:organization)
          .permit(:name, :short_name, :street, :city, :state, :zipcode, :email, :url, :logo, :intake_location, :default_email_text, :account_request_id, :reminder_day, :deadline_day,
                  users_attributes: %i(name email organization_admin), account_request_attributes: %i(ndbn_member_id id))
  end

  def user_params
    params.require(:organization).require(:user).permit(:name, :email)
  end
end
