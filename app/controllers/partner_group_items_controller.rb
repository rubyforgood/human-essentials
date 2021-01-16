class PartnerGroupItemsController < ApplicationController
  def create
    @partner_group = current_organization.partner_groups.find(params[:partner_group_id])
    @item = current_organization.items.find(params[:item_id])
    if @partner_group.partner_group_items.create(item: @item)
      redirect_to partner_group_path(@partner_group), notice: "Item #{@item.name} added to group!"
    else
      flash[:error] = "Something didn't work quite right -- try again?"
      redirect_to partner_group_path(@partner_group)
    end
  end

  def destroy
    @partner_group = current_organization.partner_groups.find(params[:partner_group_id])
    @partner_group.partner_group_items.find(params[:id]).destroy
    redirect_to partner_group_path(@partner_group)
  end
end
