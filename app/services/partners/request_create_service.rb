module Partners
  class RequestCreateService
    include ServiceObjectErrorsMixin

    attr_reader :partner_request

    def initialize(request_type:, partner_id:, user_id:, comments: nil, item_requests_attributes: [], additional_attrs: {})
      @partner_id = partner_id
      @user_id = user_id
      @comments = comments
      @request_type = request_type
      @item_requests_attributes = item_requests_attributes
      @additional_attrs = additional_attrs
    end

    def call
      initialize_only
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

    def initialize_only
      @partner_request = ::Request.new(
        partner_id: partner.id,
        organization_id: organization_id,
        comments: comments,
        request_type: request_type,
        partner_user_id: user_id
      )
      @partner_request = populate_item_request(partner_request)
      @partner_request.assign_attributes(additional_attrs)

      unless @partner_request.valid?
        @partner_request.errors.each do |error|
          errors.add(error.attribute, error.message)
        end
      end

      self
    end

    private

    attr_reader :user_id, :partner_id, :comments, :item_requests_attributes, :additional_attrs, :request_type

    def populate_item_request(partner_request)
      # Exclude any line item that is completely empty
      formatted_line_items = item_requests_attributes.reject do |attrs|
        attrs['item_id'].blank? && attrs['quantity'].blank?
      end

      items = {}

      formatted_line_items.each do |input_item|
        pre_existing_entry = items[input_item['item_id']]

        if pre_existing_entry
          unless pre_existing_entry.request_unit != input_item['request_unit']
            pre_existing_entry.quantity = (pre_existing_entry.quantity.to_i + input_item['quantity'].to_i).to_s
            # NOTE: When this code was written (and maybe it's still the
            # case as you read it!), the FamilyRequestsController does a
            # ton of calculation to translate children to item quantities.
            # If that logic is incorrect, there's not much we can do here
            # to fix things. Could make sense to move more of that logic
            # into one of the service objects that instantiate the Request
            # object (either this one or the FamilyRequestCreateService).
            pre_existing_entry.children = (pre_existing_entry.children + (input_item['children'] || [])).uniq
            next
          end
        end

        if input_item['request_unit'].to_s == '-1' # nothing selected
          errors.add(:base, "Please select a unit for #{Item.find_by_id(input_item["item_id"]).name}")
        end

        item_request = Partners::ItemRequest.new(
          item_id: input_item['item_id'],
          request_unit: input_item['request_unit'],
          quantity: input_item['quantity'],
          children: input_item['children'] || [], # will create ChildItemRequests if there are any
          name: fetch_organization_item_name(input_item['item_id']),
          partner_key: fetch_organization_partner_key(input_item['item_id'])
        )
        partner_request.item_requests << item_request
        items[input_item['item_id']] = item_request
      end

      partner_request.request_items = partner_request.item_requests.map do |ir|
        {
          item_id: ir.item_id,
          quantity: ir.quantity,
          request_unit: ir.request_unit
        }.compact
      end

      # Validate request quantity doesn't exceed the request limit for the item and unit type
      partner_request.request_items.each do |ir|
        item = Item.find_by_id(ir["item_id"])
        next if item.nil?
        unit_type = ir["request_unit"]
        quantity_requested = ir["quantity"].to_i

        limit = if unit_type.blank?
          item.unit_request_limit
        else
          item.request_units.where(name: unit_type)&.first&.request_limit
        end

        if limit.present? && (quantity_requested > limit)
          message = if unit_type.blank?
            "#{item.name}: You requested #{quantity_requested}, but are limited to #{limit}"
          else
            "#{item.name}: You requested #{quantity_requested} #{unit_type&.pluralize}, but are limited to #{limit} #{unit_type&.pluralize}"
          end
          errors.add(:base, message)
        end
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
      @partner ||= Partner.find(partner_id)
    end
  end
end
