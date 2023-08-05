require 'set'

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
      selected_children_and_items = params[:children].values.select { |child| child.has_key?("active") }
      session[:children_and_item_ids] = selected_children_and_items
      items = {}

      set = Set.new
      selected_children_and_items.each.with_index do |child_and_item, index|
        item = Item.find(child_and_item["item_id"])
        child = current_partner.children.find_by(id: child_and_item["child_id"])
        if child && item
          items[index] = { item_name: item.name, child_name: "#{child.last_name}, #{child.first_name} " }
          set << ("#{child.first_name} #{child.last_name}")
        end
      end

      @items = items.sort_by { |index, data| [data[:child_name], data[:item_name]] }.to_h

      @total_children = set.length
      @total_items_requested = @items.keys.length

      render :confirmation
    end

    def create
      child_and_item_ids = session[:children_and_item_ids].map { |child_and_item| [child_and_item["child_id"], child_and_item["item_id"]] }.uniq

      family_requests_attributes = child_and_item_ids.map do |child_id, item_id|
        child = current_partner.children.active.find_by(id: child_id)
        if child
          { item_id: item_id, person_count: 1, children: [child] }
        end
      end.compact

      create_service = Partners::FamilyRequestCreateService.new(
        partner_user_id: current_user.id,
        family_requests_attributes: family_requests_attributes,
        for_families: true
      )

      create_service.call

      session.delete(:children_and_item_ids)

      if create_service.errors.none?
        redirect_to partners_request_path(create_service.partner_request), notice: "Requested items successfully!"
      else
        redirect_to new_partners_family_request_path, error: "Request failed! #{create_service.errors.map { |error| error.message.to_s }}}"
      end
    end
  end

  def family_request_params
    params.permit(children: {})
  end
end
