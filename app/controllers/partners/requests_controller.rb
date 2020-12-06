module Partners
  class RequestsController < BaseController
    layout 'partners/application'

    protect_from_forgery with: :exception

    def index
      @partner = current_partner_user.partner
      @partner_requests = @partner.requests.order(created_at: :desc).limit(10)
    end

    def new
      @partner_request = Partners::Request.new
      @partner_request.item_requests.build

      # Fetch the valid items
      @requestable_items = Organization.find(current_partner_user.partner.diaper_bank_id).valid_items.map do |item|
        [item[:name], item[:id]]
      end.sort
    end

    def create
      create_service = Partners::RequestCreateService.new(
        partner_user_id: current_partner_user.id,
        comments: partner_request_params[:comments],
        item_requests_attributes: partner_request_params[:item_requests_attributes]&.values || []
      )

      create_service.call
      if create_service.errors.none?
        redirect_to partner_user_root_path, notice: "Request was successfully created."
      else
        @partner_request = create_service.partner_request
        @errors = create_service.errors
        @requestable_items = Organization.find(current_partner_user.partner.diaper_bank_id).valid_items.map do |item|
          [item[:name], item[:id]]
        end.sort

        render :new
      end
    end

    private

    def partner_request_params
      params.require(:partners_request).permit(:comments, item_requests_attributes: [
                                                 :item_id,
                                                 :quantity,
                                                 :_destroy
                                               ])
    end

  end
end

