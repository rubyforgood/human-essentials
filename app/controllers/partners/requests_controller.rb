module Partners
  class RequestsController < BaseController
    protect_from_forgery with: :exception

    def index
      @partner = current_partner
      @partner_requests = @partner.requests.order(created_at: :desc).limit(10)
    end

    def new
      @partner_request = ::Request.new
      @partner_request.item_requests.build

      @requestable_items = PartnerFetchRequestableItemsService.new(partner_id: current_partner.id).call
    end

    def show
      @partner_request = current_partner.requests.find(params[:id])
    end

    def create
      create_service = Partners::RequestCreateService.new(
        partner_user_id: current_user.id,
        comments: partner_request_params[:comments],
        item_requests_attributes: partner_request_params[:item_requests_attributes]&.values || []
      )

      create_service.call
      if create_service.errors.none?
        flash[:success] = 'Request was successfully created.'
        redirect_to partners_request_path(create_service.partner_request.id)
      else
        @partner_request = create_service.partner_request
        @errors = create_service.errors

        @requestable_items = PartnerFetchRequestableItemsService.new(partner_id: current_partner.id).call

        Rails.logger.info("[Request Creation Failure] partner_user_id=#{current_user.id} reason=#{@errors.full_messages}")

        render :new, status: :unprocessable_entity
      end
    end

    def validate
      @partner_request = Partners::RequestCreateService.new(
        partner_user_id: current_user.id,
        comments: partner_request_params[:comments],
        item_requests_attributes: partner_request_params[:item_requests_attributes]&.values || []
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

    def partner_request_params
      params.require(:request).permit(:comments, item_requests_attributes: [:item_id, :quantity])
    end
  end
end
