module Partners
  class IndividualsRequestsController < BaseController
    # before_action :authenticate_user!
    # before_action :verify_status_in_diaper_base
    # before_action :authorize_verified_partners

    def new
      @request = FamilyRequest.new({}, initial_items: 1)
      @requestable_items = Organization.find(current_partner.diaper_bank_id).valid_items.map do |item|
        [item[:name], item[:id]]
      end.sort
    end

    def create
      @request = FamilyRequest.new(family_request_params, partner: current_partner)

      FamilyRequestService.execute(@request)

      redirect_to partner_requests_path, notice: "Requested items successfuly!"
    rescue ActiveModel::ValidationError
      render :new
    end

    private

    def family_request_params
      params.require(:family_request)
            .permit(:comments, items_attributes: %i[item_id person_count])
    end
  end
end
