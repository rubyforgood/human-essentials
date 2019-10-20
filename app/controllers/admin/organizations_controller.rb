# [Super Admin] This is for administrating organizations at a global level. We can create, view, modify, etc.
class Admin::OrganizationsController < AdminController
  def edit
    @organization = Organization.find(params[:id])
  end

  def update
    @organization = Organization.find(params[:id])
    if @organization.update(organization_params)
      redirect_to admin_organizations_path, notice: "Updated organization!"
    else
      flash[:error] = "Failed to update this organization."
      render :edit
    end
  end

  def index
    @organizations = Organization.alphabetized.all
  end

  def new
    @organization = Organization.new
    @organization.users.build(organization_admin: true)
  end

  def create
    @organization = Organization.create(organization_params)
    @organization.users.last.update(password: SecureRandom.uuid)
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
          .permit(:name, :short_name, :street, :city, :state, :zipcode, :email, :url, :logo, :intake_location, :default_email_text,
                  users_attributes: %i(name email organization_admin))
  end
end
