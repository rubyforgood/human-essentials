module Partners
  class UsersController < BaseController
    def index
      @users = current_partner.users
    end
  end
end
