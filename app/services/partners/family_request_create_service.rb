# This service object is meant to transform a family request
# into the correct parameters that would be expected a regular
# Partners::ItemRequest. It will create the relevant Request,
# the Partners::ItemRequest(s), and Partners::ChildItemRequest(s)
module Partners
  class FamilyRequestCreateService
    include ServiceObjectErrorsMixin

    attr_reader :partner_user_id, :comments, :family_requests_attributes, :partner_request

    def initialize(partner_user_id:, family_requests_attributes:, comments: nil, for_families: false)
      @partner_user_id = partner_user_id
      @comments = comments
      @family_requests_attributes = family_requests_attributes.presence || []
      @for_families = for_families
    end

    def call
      return self unless valid?

      request_create_svc = Partners::RequestCreateService.new(
        partner_user_id: partner_user_id,
        comments: comments,
        for_families: @for_families,
        item_requests_attributes: item_requests_attributes
      )

      request_create_svc.call

      if request_create_svc.errors.any?
        request_create_svc.errors.full_messages.each do |msg|
          errors.add(:base, msg)
        end
      else
        # Store partner request so the frontend can redirect to it
        @partner_request = request_create_svc.partner_request
      end

      self
    end

    private

    def valid?
      if item_requests_attributes.any? { |attr| included_items_by_id[attr[:item_id].to_i].nil? }
        errors.add(:base, 'detected a unknown item_id')
      end

      errors.none?
    end

    def item_requests_attributes
      @item_requests_attributes ||= family_requests_attributes.filter_map do |fr_attr|
        next if fr_attr[:item_id].blank? && fr_attr[:person_count].blank?
        {
          item_id: fr_attr[:item_id],
          quantity: convert_person_count_to_item_quantity(item_id: fr_attr[:item_id], person_count: fr_attr[:person_count])&.to_i,
          children: fr_attr[:children]
        }.with_indifferent_access
      end
    end

    def convert_person_count_to_item_quantity(item_id:, person_count:)
      item = included_items_by_id[item_id.to_i]

      # Could not find matching item so return nil instead
      return nil if item.blank?

      person_count.to_i * item.default_quantity.abs
    end

    def included_items_by_id
      @included_items_by_id ||= Item.where(id: family_requests_attributes.pluck(:item_id)).index_by(&:id)
    end
  end
end
