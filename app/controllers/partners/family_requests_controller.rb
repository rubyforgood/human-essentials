module Partners
  class FamilyRequestsController < BaseController
    before_action :verify_status_in_diaper_base
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
      # The checkbox toggles in the frontend will directly set active/inactive children,
      # so fetching them from the DB here instead of reading them from params works.
      # However this is a bit of an odd pattern so we should consider taking in params as usual here
      children = current_partner.children.active.where.not(item_needed_diaperid: [nil, 0])

      children_grouped_by_item_id = children.group_by(&:item_needed_diaperid)
      family_requests_attributes = children_grouped_by_item_id.map do |item_id, item_requested_children|
        { item_id: item_id, person_count: children.count, children: item_requested_children }
      end

      create_service = Partners::FamilyRequestCreateService.new(
        partner_user_id: current_partner_user.id,
        family_requests_attributes: family_requests_attributes,
        for_families: true
      )

      create_service.call

      if create_service.errors.none?
        redirect_to partners_request_path(create_service.partner_request), notice: "Requested items successfully!"
      else
        render :new
      end
    end
  end
end
