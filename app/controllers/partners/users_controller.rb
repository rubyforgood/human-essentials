module Partners
  class UsersController < BaseController
    def index
      @users = current_partner.users
    end

    def new
      @user = User.new
    end

    def create
      user = UserInviteService.invite(name: user_params[:name],
        email: user_params[:email],
        roles: [Role::PARTNER],
        resource: current_partner)

      flash[:success] = "You have invited #{user.name} to join your organization!"
      redirect_to partners_users_path
    end

    private

    def user_params
      params.require(:user).permit(:name, :email)
    end
  end
end
