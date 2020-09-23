class Forecasting::DistributionsController < ApplicationController
  def index
    @distributions = distributions_data
  end

  private

  def distributions_data
    partner_items = []

    current_organization.partners.each do |partner|
      partner_items << {name: partner.name, data: total_items(partner.distributions)}
    end

    partner_items
  end

  def total_items(distributions)
    LineItem.where(itemizable_type: "Distribution", itemizable_id: distributions.pluck(:id))
            .group_by_month(:created_at)
            .sum(:quantity)
  end
end
