class ChildrenController < ApplicationController
  before_action :authenticate_partner!

  helper_method :child, :children, :family
  attr_reader :children, :child

  # GET /children
  # GET /children.json
  def index
    @children ||= current_partner.children.all
  end

  # GET /children/1
  # GET /children/1.json
  def show; end

  # GET /children/new
  def new
    @child = family.children.new
  end

  def active
    child = family.find(params[:child_id])
    child.active = !child.active
    child.save
  end

  # GET /children/1/edit
  def edit; end

  # POST /children
  # POST /children.json
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

  # PATCH/PUT /children/1
  # PATCH/PUT /children/1.json
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

  # DELETE /children/1
  # DELETE /children/1.json
  def destroy
    child.destroy
    respond_to do |format|
      format.html { redirect_to children_url, notice: "Child was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def child
    @child ||= current_partner.children.find(params[:id])
  end

  def family
    @family ||= current_partner.families.find_by(id: params[:family_id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def child_params
    params.require(:child).permit(
      :active,
      :agency_child_id,
      :child_lives_with,
      :comments,
      :date_of_birth,
      :first_name,
      :gender,
      :health_insurance,
      :item_needed_diaperid,
      :last_name,
      :race
    )
  end
end
