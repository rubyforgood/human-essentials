module Partners
  class RequestCreateService
    include ServiceObjectErrorsMixin

    attr_reader :partner_request

    def initialize(partner_user_id:, comments: nil, item_requests_attributes: [])
      @partner_user_id = partner_user_id
      @comments = comments
      @item_requests_attributes = item_requests_attributes
    end

    def call
      @partner_request = Partners::Request.new(partner_id: partner.id, organization_id: organization_id, comments: comments, sent: true)
      @partner_request = populate_item_request(@partner_request)

      unless @partner_request.valid?
        @partner_request.errors.each do |k, v|
          errors.add(k, v)
        end
      end

      return self if errors.present?

      Partners::Base.transaction do
        @partner_request.save!

        @organization_request = build_organization_request(@partner_request)
        @organization_request.save!

        NotifyPartnerJob.perform_now(@organization_request.id)
      rescue StandardError => e
        errors.add(:base, e.message)
        raise ActiveRecord::Rollback
      end

      self
    end

    private

    attr_reader :partner_user_id, :comments, :item_requests_attributes

    def populate_item_request(partner_request)
      item_requests = item_requests_attributes.map do |ira|
        Partners::ItemRequest.new(
          item_id: ira['item_id'],
          quantity: ira['quantity'],
          name: fetch_organization_item_name(ira['item_id']),
          partner_key: fetch_orgnaization_partner_key(ira['item_id'])
        )
      end

      partner_request.item_requests << item_requests

      partner_request
    end

    def fetch_organization_item_name(item_id)
      item_data = organization_item_data.find { |item| item[:id] == item_id.to_i }
      if item_data.present?
        item_data[:name]
      end
    end

    def fetch_orgnaization_partner_key(item_id)
      item_data = organization_item_data.find { |item| item[:id] == item_id.to_i }
      if item_data.present?
        item_data[:partner_key]
      end
    end

    def organization_item_data
      @organization_item_data ||= partner.organization.valid_items
    end

    def organization_id
      @organization_id ||= partner.diaper_bank_id
    end

    def partner
      @partner ||= Partners::User.find(partner_user_id).partner
    end

    def build_organization_request(partner_request)
      ::Request.new(
        organization_id: partner_request.organization_id,
        partner_id: partner_request.partner.diaper_partner_id,
        comments: partner_request.comments,
        request_items: partner_request.item_requests.map do |ir|
          {
            item_id: ir.item_id,
            quantity: ir.quantity
          }
        end
      )
    end
  end
end
