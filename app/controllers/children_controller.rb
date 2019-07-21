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

    respond_to do |format|
      if child.save
        format.html { redirect_to child, notice: "Child was successfully created." }
        format.json { render :show, status: :created, location: child }
      else
        format.html { render :new }
        format.json { render json: child.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if child.update(child_params)
        format.html { redirect_to child, notice: "Child was successfully updated." }
        format.json { render :show, status: :ok, location: child }
      else
        format.html { render :edit }
        format.json { render json: child.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    child.destroy
    respond_to do |format|
      format.html { redirect_to children_url, notice: "Child was successfully destroyed." }
      format.json { head :no_content }
    end
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
