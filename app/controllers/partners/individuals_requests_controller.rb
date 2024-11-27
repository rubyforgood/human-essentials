module Partners
  class IndividualsRequestsController < BaseController
    before_action :verify_partner_is_active
    before_action :authorize_verified_partners

    def new
      @request = FamilyRequest.new({}, initial_items: 1)
      @requestable_items = PartnerFetchRequestableItemsService.new(partner_id: current_partner.id).call
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
        @request = FamilyRequest.new_with_attrs(create_service.family_requests_attributes)
        @errors = create_service.errors

        @requestable_items = PartnerFetchRequestableItemsService.new(partner_id: current_partner.id).call

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
