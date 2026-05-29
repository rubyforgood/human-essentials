module View
  class Requests
    include DateRangeHelper

    attr_reader :filters, :helpers, :organization, :paginated_requests, :params, :requests

    def initialize(params:, organization:, helpers:)
      @params = params
      @organization = organization
      @filters = filter_params(params)
      @helpers = helpers

      @requests = organization
        .ordered_requests
        .undiscarded
        .during(helpers.selected_range)
        .class_filter(filters)

      @paginated_requests = requests.includes(:partner).page(params[:page])
    end

    def filter_params(params = {})
      if params.key?(:filters)
        params.require(:filters).permit(:by_request_item_id, :by_partner, :by_status, :by_request_type)
      else
        {}
      end
    end

    def unfulfilled_requests_count
      @unfulfilled_requests_count ||= organization
        .requests
        .where(status: [:pending, :started])
        .during(helpers.selected_range)
        .class_filter(filters)
        .count
    end

    def calculate_product_totals
      @calculate_product_totals ||= RequestsTotalItemsService.new(requests: requests).calculate
    end

    def items
      @items ||= organization.items.alphabetized.select(:id, :name)
    end

    def partners
      @partners ||= organization.partners.alphabetized.select(:id, :name, :status)
    end

    def statuses
      @statuses ||= Request.statuses.transform_keys(&:humanize)
    end

    def partner_users
      @partner_users ||= User.where(id: paginated_requests.map(&:partner_user_id)).select(:id, :name, :email)
    end

    def request_types
      @request_types ||= Request.request_types.transform_keys(&:humanize)
    end

    def selected_request_type
      filters[:by_request_type]
    end

    def selected_request_item
      filters[:by_request_item_id]
    end

    def selected_partner
      filters[:by_partner]
    end

    def selected_status
      filters[:by_status]
    end
  end
end
