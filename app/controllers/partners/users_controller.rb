module Partners
  class UsersController < BaseController
    def index
      @users = current_partner.users
    end

    def new
      @user = User.new
    end

    def create
      user = ::User.invite!(
        email: user_params[:email],
        name: user_params[:name]
      ) do |user|
        user.add_role(:partner, current_partner)
      end

      flash[:success] = "You have invited #{user.name} to join your organization!"
      redirect_to partners_users_path
    end

    private

    def user_params
      params.require(:user).permit(:name, :email)
    end
  end
end
