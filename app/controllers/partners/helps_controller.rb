module Partners
  class HelpsController < BaseController
    layout 'essentials_partner'

    def show
      @bank = current_partner.organization
    end
  end
end
