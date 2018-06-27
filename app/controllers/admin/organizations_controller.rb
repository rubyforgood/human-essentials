class Admin::OrganizationsController < AdminController
  def edit
    @organization = Organization.find(params[:id])
  end

  def update
    @organization = Organization.find(params[:id])
    if @organization.update_attributes(organization_params)
      redirect_to admin_organizations_path, notice: 'Updated organization!'
    else
      flash[:error] = 'Failed to update this organization.'
      render :edit
    end
  end

  def index
    @organizations = Organization.all
  end

  def invite_user
    User.invite!(email: params[:email], name: params[:name], organization_id: params[:org])
    redirect_to admin_organizations_path, notice: 'User invited to organization!'
  end

  def new
    @organization = Organization.new
  end

  def create
    @organization = Organization.create(organization_params)
    if @organization.save
      Organization.seed_items(@organization)
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
    params.require(:organization).permit(:name, :short_name, :street, :city, :state, :zipcode, :email, :url, :logo, :intake_location)
  end
end
