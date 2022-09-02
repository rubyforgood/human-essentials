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
        name: user_params[:name],
        partner: current_partner,
      )

      flash[:success] = "You have invited #{user.name} to join your organization!"
      redirect_to partners_users_path
    end

    def switch_to_bank_role
      if current_user.organization.nil?
        error_message = "Attempted to switch to a bank role but you have no bank associated with your account!"
        redirect_back(fallback_location: root_path, alert: error_message)
        return
      end

      redirect_to dashboard_path(current_user.organization)
    end

    private

    def user_params
      params.require(:user).permit(:name, :email)
    end
  end
end
