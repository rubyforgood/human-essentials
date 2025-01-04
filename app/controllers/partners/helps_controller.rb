module Partners
  class HelpsController < BaseController
    layout 'partners/application'

    def show
      @bank = current_partner.organization
    end
  end
end
