module Partners
  class RequestCreateService
    include ServiceObjectErrorsMixin

    attr_reader :partner_request

    def initialize(partner_user_id:, comments: nil, for_families: false, item_requests_attributes: [], additional_attrs: {})
      @partner_user_id = partner_user_id
      @comments = comments
      @for_families = for_families
      @item_requests_attributes = item_requests_attributes
      @additional_attrs = additional_attrs
    end

    def call
      @partner_request = ::Request.new(partner_id: partner.id,
        organization_id: organization_id,
        comments: comments,
        partner_user_id: partner_user_id)
      @partner_request = populate_item_request(@partner_request)
      @partner_request.assign_attributes(additional_attrs)

      unless @partner_request.valid?
        @partner_request.errors.each do |error|
          errors.add(error.attribute, error.message)
        end
      end

      if @partner_request.comments.blank? && @partner_request.item_requests.blank?
        errors.add(:base, 'completely empty request')
      end

      return self if errors.present?

      Request.transaction do
        @partner_request.save!

        NotifyPartnerJob.perform_now(@partner_request.id)
      rescue StandardError => e
        errors.add(:base, e.message)
        raise ActiveRecord::Rollback
      end

      self
    end

    private

    attr_reader :partner_user_id, :comments, :item_requests_attributes, :additional_attrs

    def populate_item_request(partner_request)
      # Exclude any line item that is completely empty
      formatted_line_items = item_requests_attributes.reject do |attrs|
        attrs['item_id'].blank? && attrs['quantity'].blank?
      end

      item_requests = formatted_line_items.map do |ira|
        Partners::ItemRequest.new(
          item_id: ira['item_id'],
          quantity: ira['quantity'],
          children: ira['children'] || [], # will create ChildItemRequests if there are any
          name: fetch_organization_item_name(ira['item_id']),
          partner_key: fetch_organization_partner_key(ira['item_id'])
        )
      end

      partner_request.item_requests << item_requests

      partner_request.request_items = partner_request.item_requests.map do |ir|
        {
          item_id: ir.item_id,
          quantity: ir.quantity
        }
      end
      partner_request
    end

    def fetch_organization_item_name(item_id)
      item_data = organization_item_data.find { |item| item[:id] == item_id.to_i }
      if item_data.present?
        item_data[:name]
      end
    end

    def fetch_organization_partner_key(item_id)
      item_data = organization_item_data.find { |item| item[:id] == item_id.to_i }
      if item_data.present?
        item_data[:partner_key]
      end
    end

    def organization_item_data
      @organization_item_data ||= partner.organization.valid_items
    end

    def organization_id
      @organization_id ||= partner.organization_id
    end

    def partner
      @partner ||= ::User.find(partner_user_id).partner
    end
  end
end
