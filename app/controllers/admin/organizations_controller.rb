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
      flash[:error] = "Failed to update this organization."
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

    if account_request.blank?
      @organization.users.build(organization_admin: true)
    elsif account_request.processed?
      flash[:error] = "The account request had already been processed and cannot be used again"
      @organization.users.build(organization_admin: true)
    else
      @organization.assign_attributes_from_account_request(account_request)
    end
  end

  def create
    @organization = Organization.new(organization_params)
    @organization.users.last.assign_attributes(password: SecureRandom.uuid)

    if @organization.save
      Organization.seed_items(@organization)
      @organization.users.last.invite!
      redirect_to admin_organizations_path, notice: "Organization added!"
    else
      flash[:error] = "Failed to create Organization."
      render :new
    end
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
                  users_attributes: %i(name email organization_admin))
  end
end
