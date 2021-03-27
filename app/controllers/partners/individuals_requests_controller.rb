module Partners
  class IndividualsRequestsController < BaseController
    def new
      @request = FamilyRequest.new({}, initial_items: 1)
      @requestable_items = Organization.find(current_partner.diaper_bank_id).valid_items.map do |item|
        [item[:name], item[:id]]
      end.sort
    end

    def create
      create_service = Partners::FamilyRequestCreateService.new(
        partner_user_id: current_partner_user.id,
        comments: individuals_request_params[:comments],
        family_requests_attributes: individuals_request_params[:items_attributes]&.values
      )

      create_service.call

      if create_service.errors.none?
        redirect_to partner_user_root_path, notice: "Request was successfully created."
      else
        @request = FamilyRequest.new({}, initial_items: 1)
        @errors = create_service.errors
        @requestable_items = Organization.find(current_partner.diaper_bank_id).valid_items.map do |item|
          [item[:name], item[:id]]
        end.sort

        render :new
      end
    end

    private

    def individuals_request_params
      params.require(:partners_family_request)
            .permit(:comments, items_attributes: %i[item_id person_count])
    end
  end
end
