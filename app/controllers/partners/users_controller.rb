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
        flash_error_unless_summarised(@user, "Failed to update this user.")
        render :edit
      end
    end

    # partner user creation
    def create
      user = UserInviteService.invite(name: user_params[:name],
        email: user_params[:email],
        roles: [Role::PARTNER],
        resource: current_partner)

      if user.errors.none?
        flash[:success] = "You have invited #{user.display_name} to join your organization!"
        redirect_to partners_users_path
      else
        # Re-render, do not redirect. A redirect threw away the errors AND everything typed, so
        # the form came back empty with a flash and no indication of which field was wrong.
        @user = user
        render :new, status: :unprocessable_content
      end
    rescue => e
      # The service also raises for things with no field to attach to -- an unknown role, a
      # resource that is gone -- and those stay a message above the form.
      @user = User.new(user_params)
      flash_error_unless_summarised(@user, e.message)
      render :new, status: :unprocessable_content
    end

    private

    def user_params
      modified_params = params.require(:user).permit(:name, :email)
      modified_params[:name] = nil if modified_params[:name].blank?
      modified_params
    end
  end
end
