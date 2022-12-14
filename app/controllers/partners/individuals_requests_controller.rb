module Partners
  class IndividualsRequestsController < BaseController
    def new
      @request = FamilyRequest.new({}, initial_items: 1)

      requestable_items = PartnerFetchRequestableItemsService.new(partner_id: current_partner.id).call
      @formatted_requestable_items = requestable_items.map do |rt|
        [rt.name, rt.id]
      end.sort
    end

    def create
      create_service = Partners::FamilyRequestCreateService.new(
        partner_user_id: current_user.id,
        comments: individuals_request_params[:comments],
        family_requests_attributes: individuals_request_params[:items_attributes]&.values
      )

      create_service.call

      if create_service.errors.none?
        flash[:success] = 'Request was successfully created.'
        redirect_to partners_request_path(create_service.partner_request.id)
      else
        @request = FamilyRequest.new({}, initial_items: 1)
        @errors = create_service.errors
        @requestable_items = Organization.find(current_partner.organization_id).valid_items.map do |item|
          [item[:name], item[:id]]
        end.sort

        Rails.logger.info("[Request Creation Failure] partner_user_id=#{current_user.id} reason=#{@errors.full_messages}")

        render :new, status: :unprocessable_entity
      end
    end

    private

    def individuals_request_params
      params.require(:partners_family_request)
            .permit(:comments, items_attributes: %i[item_id person_count])
    end
  end
end
