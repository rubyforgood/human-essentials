class PartnerGroupsController < ApplicationController
  before_action :set_partner_group, only: %i[edit destroy]

  def new
    @partner_group = current_organization.partner_groups.new
    set_items_categories
  end

  def create
    @partner_group = current_organization.partner_groups.new(partner_group_params)
    if @partner_group.save
      # Redirect to groups tab in Partner page.
      redirect_to partners_path + "#nav-partner-groups", notice: "Partner group added!"
    else
      flash.now[:error] = "Something didn't work quite right -- try again?"
      set_items_categories
      render action: :new
    end
  end

  def edit
    @partner_group = current_organization.partner_groups.find(params[:id])
    set_items_categories
  end

  def update
    @partner_group = current_organization.partner_groups.find(params[:id])
    if @partner_group.update(partner_group_params)
      redirect_to partners_path + "#nav-partner-groups", notice: "Partner group edited!"
    else
      flash.now[:error] = "Something didn't work quite right -- try again?"
      set_items_categories
      render action: :edit
    end
  end

  def destroy
    if @partner_group.partners.any?
      redirect_to partners_path + "#nav-partner-groups", alert: "Partner Group cannot be deleted."
    else
      @partner_group.destroy
      respond_to do |format|
        format.html { redirect_to partners_path + "#nav-partner-groups", notice: "Partner Group was successfully deleted." }
      end
    end
  end

  private

  def set_partner_group
    @partner_group = current_organization.partner_groups.find(params[:id])
  end

  def partner_group_params
    params.require(:partner_group).permit(:name, :send_reminders, :deadline_day, :reminder_day, item_category_ids: [])
  end

  def set_items_categories
    @item_categories = current_organization.item_categories
  end
end
