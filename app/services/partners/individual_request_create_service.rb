module Partners
  class IndividualRequestCreateService
    include ServiceObjectErrorsMixin

    #
    # This service object is meant to transform an individual request
    # into the correct parameters that would be expected in a
    # regular request.
    #

    def initialize(partner_user_id:, comments: nil, family_requests_attributes: [])
      @partner_user_id = partner_user_id
      @comments = comments
      @family_requests_attributes = family_requests_attributes
    end

    def call
      return self unless valid?

      request_create_svc = Partners::RequestCreateService.new(
        partner_user_id: partner_user_id,
        comments: comments,
        item_requests_attributes: item_requests_attributes
      )

      request_create_svc.call

      if request_create_svc.errors.any?
        request_create_svc.errors.full_messages.each do |msg|
          errors.add(:base, msg)
        end
      end

      self
    end

    private

    attr_reader :partner_user_id, :comments, :family_requests_attributes

    def valid?
      if family_requests_attributes.blank?
        errors.add(:base, 'family_requests_attributes cannot be empty')
      end

      if item_requests_attributes.any? { |attr| attr[:item_id].nil? }
        errors.add(:base, 'detected a unknown item_id')
      end

      errors.none?
    end

    def item_requests_attributes
      @item_requests_attributes ||= family_requests_attributes.map do |fr_attr|
        item = included_items.find { |i| i.id == fr_attr[:item_id].to_i }

        {
          item_id: item&.id,
          quantity: convert_person_count_to_item_quantity(item_id: fr_attr[:item_id], person_count: fr_attr[:person_count])&.to_i
        }.with_indifferent_access
      end
    end

    def convert_person_count_to_item_quantity(item_id:, person_count:)
      item = included_items.find { |i| i.id == item_id.to_i }

      # Could not find matching item so return nil instead
      return nil if item.blank?

      person_count.to_i * item.default_quantity.abs
    end

    def included_items
      @included_items ||= Item.where(id: family_requests_attributes.map { |fr_attr| fr_attr[:item_id] })
    end
  end
end
