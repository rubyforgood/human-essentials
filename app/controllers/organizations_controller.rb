class OrganizationsController < ApplicationController
  def edit
    @organization = current_organization
  end

  def update
    @organization = current_organization

    if current_organization.update_attributes(organization_params)
      redirect_to edit_organization_path, notice: 'Updated organization!'
    else
      flash[:alert] = 'Failed to update organization'
      render :edit
    end
  end

  def new
  end

  def create
  end

  private

  def organization_params
    params.require(:organization).permit(:name, :short_name, :address, :email, :url)
  end
end
