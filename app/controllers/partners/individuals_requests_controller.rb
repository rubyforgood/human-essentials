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
        family_requests_attributes: individuals_request_params[:items_attributes]&.values,
        request_type: "individual"
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

    def validate
      @partner_request = Partners::FamilyRequestCreateService.new(
        partner_user_id: current_user.id,
        comments: individuals_request_params[:comments],
        family_requests_attributes: individuals_request_params[:items_attributes]&.values,
        request_type: "individual"
      ).initialize_only
      if @partner_request.valid?
        @total_items = @partner_request.total_items
        @quota_exceeded = current_partner.quota_exceeded?(@total_items)
        body = render_to_string(template: 'partners/requests/validate', formats: [:html], layout: false)
        render json: {valid: true, body: body}
      else
        render json: {valid: false}
      end
    end

    private

    def individuals_request_params
      params.require(:partners_family_request)
            .permit(:comments, items_attributes: %i[item_id person_count])
    end
  end
end
