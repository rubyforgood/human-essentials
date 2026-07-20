module View
  class ProductDriveParticipants
    attr_reader :filters, :params, :participants

    def initialize(params:, organization:)
      @params = params
      @filters = filter_params(params)

      @participants = organization
        .product_drive_participants
        .includes(:donations)
        .with_volumes
        .class_filter(filters)
        .order(:business_name)
    end

    def filter_params(params = {})
      if params.key?(:filters)
        params.require(:filters).permit(:by_business_name, :by_contact_name)
      else
        {}
      end
    end

    def selected_business_name
      filters[:by_business_name]
    end

    def selected_contact_name
      filters[:by_contact_name]
    end
  end
end
