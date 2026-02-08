module View
  Donations = Data.define(
    :donations,
    :filters,
    :items,
    :item_categories,
    :paginated_donations,
    :product_drives,
    :product_drive_participants,
    :storage_locations,
    :donation_sites,
    :manufacturers
  ) do
    include DateRangeHelper

    class << self
      def filter_params(params)
        if params.key?(:filters)
          params.require(:filters).permit(
            :at_storage_location, :by_source, :from_donation_site,
            :by_product_drive, :by_product_drive_participant,
            :from_manufacturer, :by_item_id, :by_item_category_id,
            :by_category
          )
        else
          {}
        end
      end

      def from_params(params:, organization:, helpers:)
        filters = filter_params(params)
        donations = organization.donations
          .includes(:storage_location,
            :donation_site,
            :product_drive,
            :product_drive_participant,
            :manufacturer,
            line_items: [:item])
          .order(created_at: :desc)
          .class_filter(filters)
          .during(helpers.selected_range)

        paginated_donations = donations.page(params[:page])

        storage_locations = donations.filter_map do |donation|
          donation.storage_location unless donation.storage_location.discarded_at
        end.compact.uniq.sort

        manufacturers = donations.collect(&:manufacturer).compact.uniq.sort

        new(
          donations: donations,
          filters: filters,
          items: organization.items.alphabetized.select(:id, :name),
          item_categories: organization.item_categories.pluck(:name).uniq,
          paginated_donations: paginated_donations,
          product_drives: organization.product_drives.alphabetized,
          product_drive_participants: organization.product_drive_participants.alphabetized,
          storage_locations: storage_locations,
          donation_sites: donations.map(&:donation_site).compact.uniq.sort_by { |site| site.name.downcase },
          manufacturers: manufacturers
        )
      end
    end

    def selected_storage_location
      filters[:at_storage_location]
    end

    def selected_source
      filters[:by_source]
    end

    def selected_item
      filters[:by_item_id].presence
    end

    def selected_item_category
      filters[:by_category]
    end

    def sources
      donations.map(&:source).uniq.sort
    end

    def donations_quantity
      donations.map(&:total_quantity).sum
    end

    def selected_donation_site
      filters[:from_donation_site]
    end

    def selected_product_drive
      filters[:by_product_drive]
    end

    def selected_product_drive_participant
      filters[:by_product_drive_participant]
    end

    def selected_manufacturer
      filters[:from_manufacturer]
    end

    def paginated_donations_quantity
      paginated_donations.map(&:total_quantity).sum
    end

    def paginated_in_kind_value
      paginated_donations.sum { |donation| donation.value_per_itemizable }
    end

    def total_money_raised
      donations.sum { |d| d.money_raised.to_i }
    end

    def total_value_all_donations
      donations.sum { |donation| donation.value_per_itemizable }
    end
  end
end
