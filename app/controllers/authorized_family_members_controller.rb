class AuthorizedFamilyMembersController < ApplicationController
  helper_method :authorized_family_member, :authorized_family_members, :family

  def new; end

  def show; end

  def edit; end

  def create
    member = family.authorized_family_members.new(authorized_family_member_params)

    respond_to do |format|
      if member.save
        format.html { redirect_to member, notice: "Authorized member was successfully created." }
        format.json { render :root }
      else
        format.html { render :new }
        format.json { render json: member.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if authorized_family_member.update(authorized_family_member_params)
        format.html { redirect_to authorized_family_member, notice: "Authorized family member was successfully updated." }
        format.json { render :show, status: :ok, location: authorized_family_member }
      else
        format.html { render :edit }
        format.json { render json: authorized_family_member.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def authorized_family_member
    @authorized_family_member ||= current_partner.authorized_family_members.find_by(id: params[:id]) ||
                                  family.authorized_family_members.new
  end

  def authorized_family_members
    @authorized_family_members ||= current_partner.authorized_family_members.all
  end

  def family
    @family ||= current_partner.families.find_by(id: params[:family_id])
  end

  def authorized_family_member_params
    params.require(:authorized_family_member).permit(
      :first_name,
      :last_name,
      :date_of_birth,
      :gender,
      :comments
    )
  end
end