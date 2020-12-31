class PartnerGroupMembershipsController < ApplicationController
  def create
    @partner_group = current_organization.partner_groups.find(params[:partner_group_id])
    @partner = current_organization.partners.find(params[:partner_id])
    if @partner_group.partner_group_memberships.create(partner: @partner)
      redirect_to partner_group_path(@partner_group), notice: "Partner #{@partner.name} added to group!"
    else
      flash[:error] = "Something didn't work quite right -- try again?"
      redirect_to partner_group_path(@partner_group)
    end
  end

  def destroy
    @partner_group = current_organization.partner_groups.find(params[:partner_group_id])
    @partner_group.partner_group_memberships.find(params[:id]).destroy
    redirect_to partner_group_path(@partner_group)
  end
end
