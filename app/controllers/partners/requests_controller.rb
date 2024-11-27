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

    private

    def partner_request_params
      params.require(:request).permit(:comments, item_requests_attributes: [:item_id, :quantity])
    end
  end
end
