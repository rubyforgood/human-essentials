class OrganizationsController < ApplicationController
  def edit
    @organization = current_organization
  end

  def update
    @organization = current_organization
    if @organization.update(organization_params)
      redirect_to edit_organization_path(organization_id: current_organization.to_param), notice: "Updated organization!"
    else
      flash[:error] = "Failed to update organization"
      render :edit
    end
  end

  private

  def organization_params
    params.require(:organization).permit(:name, :short_name, :street, :city, :state, :zipcode, :email, :url, :logo, :intake_location)
  end
end
