module Partners
  class BaseController < ApplicationController
    skip_before_action :authenticate_user!
    skip_before_action :authorize_user
    before_action :authenticate_partner_user!
  end
end
