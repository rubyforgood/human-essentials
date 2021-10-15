module Reports
  class AdultIncontinenceReportService
    ADULT_INCONTINENCE_TYPES = %w[adult_incontinence underpads pads liners].freeze
    attr_reader :year, :organization

    def initialize(year:, organization:)
      @year = year
      @organization = organization
    end

    def report
      @report ||= {
        money_spent: money_spent,
        monthly_adult_incontinence: monthly_adult_incontinence,
        provided_per_person: provided_per_person,
        supplies_distributed: supplies_distributed,
        supplies_purchased: supplies_purchased,
        supplies_received: supplies_received
      }
    end

    def columns_for_csv
      %i[supplies_distributed monthly_adult_incontinence
         supplies_received supplies_purchased]
    end

    def adult_incontinence_items
      organization.items.where(partner_key: ADULT_INCONTINENCE_TYPES)
    end

    def monthly_adult_incontinence
      # TODO: need to know how many adults this is distributed too
      # This is just a monthly average now, but needs to be per person
      yearly_line_item_total / 12.0
    end

    def adult_incontinence_line_items
      LineItem.where(item: adult_incontinence_items)
    end

    def yearly_line_item_total
      @yearly_line_item_total ||= adult_incontinence_line_items.where(itemizable: yearly_purchases).or(
        adult_incontinence_line_items.where(itemizable: yearly_donations)
      ).sum(:quantity)
    end

    def supplies_distributed
      adult_incontinence_line_items.where(itemizable: yearly_distributions)
                                   .sum(:quantity)
    end

    def supplies_received
      return 0 if yearly_line_item_total <= 0

      count = adult_incontinence_line_items.where(itemizable: yearly_donations)
                                           .sum(:quantity)

      (count.to_f / yearly_line_item_total) * 100
    end

    def supplies_purchased
      return 0 if yearly_line_item_total <= 0

      count = adult_incontinence_line_items.where(itemizable: yearly_purchases)
                                           .sum(:quantity)

      (count.to_f / yearly_line_item_total) * 100
    end

    def total_adults_distributed_to
      # TODO: find this value
      100
    end

    def provided_per_person
      supplies_distributed / total_adults_distributed_to
    end

    def money_spent
      # TODO: Implement me.
    end

    def yearly_distributions
      ::Distribution.where(organization: organization)
                    .where("extract(year  from issued_at) = ?", year)
    end

    def yearly_donations
      ::Donation.where(organization: organization)
                .where("extract(year  from issued_at) = ?", year)
    end

    def yearly_purchases
      ::Purchase.where(organization: organization)
                .where("extract(year  from issued_at) = ?", year)
    end
  end
end
