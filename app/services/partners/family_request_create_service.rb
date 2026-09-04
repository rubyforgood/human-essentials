# This service object is meant to transform a family request
# into the correct parameters that would be expected a regular
# Partners::ItemRequest. It will create the relevant Request,
# the Partners::ItemRequest(s), and Partners::ChildItemRequest(s)
module Partners
  class FamilyRequestCreateService
    include ServiceObjectErrorsMixin

    attr_reader :partner_user_id, :comments, :family_requests_attributes, :partner_request, :request_type

    def initialize(partner_user_id:, family_requests_attributes:, request_type:, comments: nil)
      @partner_user_id = partner_user_id
      @comments = comments
      @family_requests_attributes = family_requests_attributes.presence || []
      @request_type = request_type
    end

    def call
      return self unless valid?

      request_create_svc = Partners::RequestCreateService.new(
        partner_id: partner.id,
        user_id: partner_user_id,
        comments: comments,
        request_type: request_type,
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

    def initialize_only
      Partners::RequestCreateService.new(
        partner_id: partner.id,
        user_id: partner_user_id,
        comments: comments,
        request_type: request_type,
        item_requests_attributes: item_requests_attributes
      ).initialize_only
    end

    private

    def valid?
      # A submitted item that is not in the partner's requestable set. Every id on this form comes
      # from the form itself, so a partner cannot reach this by filling it in wrongly -- getting
      # here means the page and the server disagree, which is a bug on our side.
      #
      # The message says that, rather than being tidied into a neater sentence about item ids: it
      # is rendered verbatim as a bullet in `partners/requests/_error`, and telling someone their
      # "item_id" was "unknown" invites them to hunt for a mistake they did not make. Naming the
      # bank is the only useful action available to them.
      if item_requests_attributes.any? { |attr| included_items_by_id[attr[:item_id].to_i].nil? }
        errors.add(:base, "Something went wrong at our end and this request could not be read. " \
                          "Nothing you did caused it -- please contact your bank.")
      end

      check_for_item_visibility

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

    # If requested item(s) isn't visible to partners,
    # an error specifying which item is not available is raised
    def check_for_item_visibility
      invisible_items = item_requests_attributes.select { |attr|
        !included_items_by_id[attr[:item_id]].nil? &&
          !included_items_by_id[attr[:item_id]].visible_to_partners
      }

      unless invisible_items.empty?

        item_errors = invisible_items.map do |item|
          item_name = included_items_by_id[item[:item_id]].name

          children_names = item[:children].map { |c| "#{c.first_name} #{c.last_name}" }.join(", ")

          "\"#{item_name}\" requested for #{children_names} is not currently available for request."
        end

        joined_errors = item_errors.join(", ")

        # don't want to show a memflash error
        if joined_errors.length >= Memflash.threshold
          truncated_errors = joined_errors[0...(Memflash.threshold - 10)]
          errors.add(:base, "#{truncated_errors}...")
        else
          errors.add(:base, joined_errors)
        end

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

    def partner
      @partner ||= ::User.find(partner_user_id).partner
    end
  end
end
