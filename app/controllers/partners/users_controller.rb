module Partners
  class UsersController < BaseController
    def index
      @users = current_partner.users
    end

    def new
      @user = User.new
    end

    def edit
      @user = current_user
    end

    def update
      @user = current_user
      if @user.update(user_params)
        flash[:success] = "User information was successfully updated!"
        redirect_to edit_partners_user_path(@user)
      else
        flash[:error] = "Failed to update this user."
        render :edit
      end
    end

    def create
      # this pre-creation work is to determine whether the user has accepted the invitation or not - if they have, then a new email is not sent
      @user = User.find_by(email: user_params[:email])
      if @user && (@user.last_sign_in_at? || @user.invitation_accepted_at?)
        flash[:error] = "#{@user.name} has already joined the organization"
        redirect_to partners_users_path
      else
        #everything from here on runs only if the revious condition is met
        user = UserInviteService.invite(name: user_params[:name],
          email: user_params[:email],
          roles: [Role::PARTNER],
          resource: current_partner)
        if user.errors.none?
          flash[:success] = "You have invited #{user.name} to join your organization!"
          redirect_to partners_users_path
        else
          flash[:error] = user.errors.full_messages.join("")
          redirect_to new_partners_user_path
        end
      end
    end

    private

    def user_params
      params.require(:user).permit(:name, :email)
    end
  end
end
