module Partners
  class AuthorizedFamilyMembersController < BaseController
    layout 'essentials_partner'

    def new
      # The route is not nested under families, so family_id arrives as a query parameter -- and
      # a visit without one made `family` nil and this a 500 rather than a page. Every link to
      # here supplies it; a bookmark, a typo or an audit does not.
      return redirect_to partners_families_path, error: "Choose a family first." if family.nil?

      @authorized_family_member = family.authorized_family_members.new
    end

    def show
      @authorized_family_member = current_partner.authorized_family_members.find(params[:id])
    end

    def edit
      @authorized_family_member = current_partner.authorized_family_members.find_by(id: params[:id])
    end

    def create
      @authorized_family_member = family.authorized_family_members.new(authorized_family_member_params)

      if @authorized_family_member.save
        redirect_to @authorized_family_member, notice: "Authorized member was successfully created."
      else
        render :new
      end
    end

    def update
      @authorized_family_member = current_partner.authorized_family_members.find_by(id: params[:id])

      if @authorized_family_member.update(authorized_family_member_params)
        redirect_to @authorized_family_member, notice: "Authorized family member was successfully updated."
      else
        render :edit
      end
    end

    def destroy
      @authorized_family_member = current_partner.authorized_family_members.find_by(id: params[:id])
      if @authorized_family_member.present?
        @authorized_family_member.destroy
        redirect_back_or_to(partners_families_url, notice: "Authorized family member removed.")
      end
    end

    private

    def family
      @family ||= current_partner.families.find_by(id: params[:family_id])
    end

    def authorized_family_member_params
      params.require(:partners_authorized_family_member).permit(
        :first_name,
        :last_name,
        :date_of_birth,
        :gender,
        :comments
      )
    end
  end
end