class OrganizationsController < ApplicationController
  def edit
    @current_organization = current_organization
  end

  def update
    @current_organization = current_organization

    if @current_organization.update(organization_params)
      redirect_to edit_organization_path(organization_id: current_organization.to_param),
                  notice: "Updated organization!"
    else
      flash[:error] = "Failed to update organization"
      render :edit
    end
  end

  # TODO: who should be able to arrive here and how?
  def new; end

  # TODO: who should be able to arrive here and how?
  def create; end

  private

  def organization_params
    params.require(:organization).permit(:name, :short_name,
                                         :address, :email, :url,
                                         :logo, :intake_location)
  end
end
