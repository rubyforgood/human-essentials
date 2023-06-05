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

    def confirmation
      @children_ids = params.keys.select { |key| key.start_with?('child') && params[key] == "true" }.map { |key| key.split('-').last }
      children = current_partner.children.active.where(id: @children_ids).where.not(item_needed_diaperid: [nil, 0])
      children_grouped_by_item_id = children.group_by(&:item_needed_diaperid)

      @items = {}
      children_grouped_by_item_id.each do |item_id, item_requested_children|
        item = Item.find(item_id)
        unless item.nil?
          @items[item.name] = {
            count: item_requested_children.size,
            children: item_requested_children.map { |child| {first_name: child.first_name, last_name: child.last_name} }
          }
        end
      end
      render :confirmation
    end

    def create
      children_ids = []

      params.each do |key, _|
        is_child, id = key.split('-')
        if is_child == 'child'
          children_ids << id
        end
      end

      children = current_partner.children.active.where(id: children_ids).where.not(item_needed_diaperid: [nil, 0])

      children_grouped_by_item_id = children.group_by(&:item_needed_diaperid)
      family_requests_attributes = children_grouped_by_item_id.map do |item_id, item_requested_children|
        { item_id: item_id, person_count: item_requested_children.size, children: item_requested_children }
      end

      create_service = Partners::FamilyRequestCreateService.new(
        partner_user_id: current_user.id,
        family_requests_attributes: family_requests_attributes,
        for_families: true
      )

      create_service.call

      if create_service.errors.none?
        redirect_to partners_request_path(create_service.partner_request), notice: "Requested items successfully!"
      else
        redirect_to new_partners_family_request_path, error: "Request failed! #{create_service.errors.map { |error| error.message.to_s }}}"
      end
    end
  end
end
