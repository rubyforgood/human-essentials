class ChildrenController < ApplicationController
  before_action :authenticate_user!

  def index
    @children = current_partner.children.order(active: :desc, last_name: :asc)
  end

  def show
    @child = current_partner.children.find_by(id: params[:id])
  end

  def new
    @child = family.children.new
  end

  def active
    child = current_partner.children.find(params[:child_id])
    child.active = !child.active
    child.save
  end

  def edit
    @child = current_partner.children.find_by(id: params[:id])
  end

  def create
    child = family.children.new(child_params)

    if child.save
      redirect_to child, notice: "Child was successfully created."
    else
      render :new
    end
  end

  def update
    child = current_partner.children.find_by(id: params[:id])

    if child.update(child_params)
      redirect_to child, notice: "Child was successfully updated."
    else
      render :edit
    end
  end

  def destroy
    child = current_partner.children.find_by(id: params[:id])
    child.destroy
    redirect_to children_url, notice: "Child was successfully destroyed."
  end

  private

  def family
    @_family ||= current_partner.families.find_by(id: params[:family_id])
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
