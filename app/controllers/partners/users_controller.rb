module Partners
  class UsersController < BaseController
    def index
      @users = current_partner.users
    end

    def new
      @user = User.new
    end
  end
end
