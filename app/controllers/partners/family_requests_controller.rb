module Partners
  class FamilyRequestsController < BaseController
    before_action :verify_partner_is_active
    before_action :authorize_verified_partners

    def new
      @filterrific = initialize_filterrific(
        current_partner.children
                       .order(last_name: :asc)
                       .order(first_name: :asc),
        params[:filterrific]
      ) || return
      @children = @filterrific.find
    end

    def create
      family_requests_attributes = build_family_requests_attributes(params)

      create_service = Partners::FamilyRequestCreateService.new(
        partner_user_id: current_user.id,
        family_requests_attributes: family_requests_attributes,
        request_type: "child"
      )

      create_service.call

      if create_service.errors.none?
        redirect_to partners_request_path(create_service.partner_request), notice: "Requested items successfully!"
      else
        redirect_to new_partners_family_request_path, error: "Request failed! #{create_service.errors.map { |error| error.message.to_s }}}"
      end
    end

    def validate
      family_requests_attributes = build_family_requests_attributes(params)

      @partner_request = Partners::FamilyRequestCreateService.new(
        partner_user_id: current_user.id,
        family_requests_attributes: family_requests_attributes,
        request_type: "child"
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

    def build_family_requests_attributes(params)
      children_ids = []

      params.each do |key, _|
        is_child, id = key.split('-')
        if is_child == 'child'
          children_ids << id
        end
      end

      children = current_partner.children.where(id: children_ids).joins(:requested_items).select('children.*', :item_id)

      children_grouped_by_item_id = children.group_by(&:item_id)
      children_grouped_by_item_id.map do |item_id, item_requested_children|
        { item_id: item_id, person_count: item_requested_children.size, children: item_requested_children }
      end
    end
  end
end
