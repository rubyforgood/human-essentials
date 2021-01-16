class PartnerGroupsController < ApplicationController
  def index
    @partner_groups = current_organization.partner_groups

    respond_to do |format|
      format.html
    end
  end

  def show
    @partner_group = current_organization.partner_groups.find(params[:id])

    @partners_not_in_group = current_organization.partners.alphabetized - @partner_group.partners
    @items_not_in_group = current_organization.items.alphabetized - @partner_group.items

    respond_to do |format|
      format.html
    end
  end

  def new
    @partner_group = current_organization.partner_groups.new
  end

  def create
    @partner_group = current_organization.partner_groups.new(partner_group_params)
    if @partner_group.save
      redirect_to partner_groups_path, notice: "Partner group added!"
    else
      flash[:error] = "Something didn't work quite right -- try again?"
      render action: :new
    end
  end

  def edit
    @partner_group = current_organization.partner_groups.find(params[:id])
  end

  def update
    @partner_group = current_organization.partner_groups.find(params[:id])
    if @partner_group.update(partner_group_params)
      redirect_to partner_group_path(@partner_group), notice: "#{@partner_group.name} updated!"
    else
      flash[:error] = "Something didn't work quite right -- try again?"
      render action: :edit
    end
  end

  def destroy
    current_organization.partner_groups.find(params[:id]).destroy
    redirect_to partner_groups_path
  end

  private

  def partner_group_params
    params.require(:partner_group).permit(:name)
  end
end
