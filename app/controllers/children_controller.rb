class ChildrenController < ApplicationController
  before_action :authenticate_partner!

  helper_method :child, :children, :family

  def index; end

  def show; end

  def new; end

  def active
    child = current_partner.children.find(params[:child_id])
    child.active = !child.active
    child.save
  end

  def edit; end

  def create
    child = family.children.new(child_params)

    if child.save
      redirect_to child, notice: "Child was successfully created."
    else
      render :new
    end
  end

  def update
    if child.update(child_params)
      redirect_to child, notice: "Child was successfully updated."
      render :show, status: :ok, location: child
    else
      render :edit
    end
  end

  def destroy
    child.destroy
    redirect_to children_url, notice: "Child was successfully destroyed."
  end

  private

  def children
    @children ||= current_partner.children.all
  end

  def child
    @child ||= current_partner.children.find_by(id: params[:id]) ||
               family.children.new
  end

  def family
    @family ||= current_partner.families.find_by(id: params[:family_id])
  end

  def child_params
    params.require(:child).permit(
      :active,
      :agency_child_id,
      :comments,
      :date_of_birth,
      :first_name,
      :gender,
      :health_insurance,
      :item_needed_diaperid,
      :last_name,
      :race,
      :archived,
      child_lives_with: []
    )
  end
end
