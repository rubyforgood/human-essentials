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

    private

    def user_params
      params.require(:user).permit(:name, :email)
    end
  end
end
