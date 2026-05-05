module View
  Requests = Data.define(
    :requests,
    :filters,
    :paginated_requests,
    :organization,
    :helpers
  ) do
    include DateRangeHelper

    class << self
      def filter_params(params = {})
        if params.key?(:filters)
          params.require(:filters).permit(:by_request_item_id, :by_partner, :by_status, :by_request_type)
        else
          {}
        end
      end

      def from_params(params:, organization:, helpers:)
        filters = filter_params(params)

        requests = organization
          .ordered_requests
          .undiscarded
          .during(helpers.selected_range)
          .class_filter(filters)

        paginated_requests = requests.includes(:partner).page(params[:page])

        new(requests:, filters:, paginated_requests:, organization:, helpers:)
      end
    end

    def unfulfilled_requests_count
      organization
        .requests
        .where(status: [:pending, :started])
        .during(helpers.selected_range)
        .class_filter(filters)
        .count
    end

    def calculate_product_totals
      RequestsTotalItemsService.new(requests: requests).calculate
    end

    def items
      organization.items.alphabetized.select(:id, :name)
    end

    def partners
      organization.partners.alphabetized.select(:id, :name, :status)
    end

    def statuses
      Request.statuses.transform_keys(&:humanize)
    end

    def partner_users
      User.where(id: paginated_requests.map(&:partner_user_id)).select(:id, :name, :email)
    end

    def request_types
      Request.request_types.transform_keys(&:humanize)
    end

    def selected_request_type
      filter_params[:by_request_type]
    end

    def selected_request_item
      filter_params[:by_request_item_id]
    end

    def selected_partner
      filter_params[:by_partner]
    end

    def selected_status
      filter_params[:by_status]
    end
  end
end
