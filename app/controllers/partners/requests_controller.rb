module Partners
  class RequestsController < BaseController
    skip_before_action :require_partner, only: [:new, :create, :validate]
    before_action :require_partner_or_org_admin, only: [:new, :create, :validate]
    layout :layout

    protect_from_forgery with: :exception

    def index
      @partner = current_partner
      @partner_requests = @partner.requests.includes(:item_requests).order(created_at: :desc).limit(10)
    end

    def new
      @partner_request = ::Request.new
      @partner_request.item_requests.build

      fetch_items
    end

    def show
      @partner_request = current_partner.requests.find(params[:id])
    end

    def create
      create_service = Partners::RequestCreateService.new(
        request_type: "quantity",
        partner_id: partner.id,
        user_id: current_user.id,
        comments: partner_request_params[:comments],
        item_requests_attributes: partner_request_params[:item_requests_attributes]&.values || []
      )

      create_service.call
      if create_service.errors.none?
        flash[:success] = 'Request was successfully created.'
        if current_partner
          redirect_to partners_request_path(create_service.partner_request.id)
        else
          redirect_to request_path(create_service.partner_request.id)
        end
      else
        @partner_request = create_service.partner_request
        @errors = create_service.errors

        fetch_items

        Rails.logger.info("[Request Creation Failure] partner_user_id=#{current_user.id} reason=#{@errors.full_messages}")

        render :new, status: :unprocessable_entity
      end
    end

    def validate
      create_service = Partners::RequestCreateService.new(
        request_type: "quantity",
        partner_id: partner.id,
        user_id: current_user.id,
        comments: partner_request_params[:comments],
        item_requests_attributes: partner_request_params[:item_requests_attributes]&.values || []
      ).initialize_only

      if create_service.errors.none?
        @partner_request = create_service.partner_request
        @total_items = @partner_request.total_items
        @quota_exceeded = partner.quota_exceeded?(@total_items)
        body = render_to_string(template: 'partners/requests/validate', formats: [:html], layout: false)
        render json: {valid: true, body: body}
      else
        render json: {valid: false}
      end
    end

    private

    def partner_request_params
      params.require(:request).permit(:comments, item_requests_attributes: [:item_id, :quantity, :request_unit])
    end

    def fetch_items
      @requestable_items = PartnerFetchRequestableItemsService.new(partner_id: partner.id).call
      if Flipper.enabled?(:enable_packs)
        # hash of (item ID => hash of (request unit name => request unit plural name))
        @item_units = Item.where(id: @requestable_items.to_h.values).to_h do |i|
          [i.id, i.request_units.to_h { |u| [u.name, u.name.pluralize] }]
        end
      end
    end

    def require_partner_or_org_admin
      return if current_partner

      partner_id = params.permit(:partner_id)[:partner_id]
      return redirect_invalid_user if partner_id.blank?

      partner = Partner.find(partner_id)
      if current_user.has_role?(Role::ORG_ADMIN, current_organization) && current_organization == partner&.organization
        @partner = partner
      else
        redirect_invalid_user
      end
    end

    def redirect_invalid_user
      respond_to do |format|
        format.html { redirect_to dashboard_path, flash: {error: "Logged in user is not set up as a 'partner'."} }
        format.json { render body: nil, status: :forbidden }
      end
    end

    def partner
      @partner ||= current_partner
    end

    def layout
      @layout ||= current_partner ? "partners/application" : "application"
    end
  end
end
