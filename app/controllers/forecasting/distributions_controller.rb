class Forecasting::DistributionsController < ApplicationController
  def index
    @series     = series
    @categories = categories
  end

  private

  def series
    items = []

    current_organization.items.sort.each do |item|
      items << {name: item.name, data: total_items(item.line_items).values}
    end

    items.to_json
  end

  def categories
    keys = total_items(LineItem.all).keys

    dates(keys)
  end

  def dates(dates)
    dates.sort.uniq.map {|date| Date::ABBR_MONTHNAMES[date.month]}
  end

  def total_items(line_items)
    line_items.where(itemizable_type: "Distribution")
              .group_by_month(:created_at)
              .sum(:quantity)
  end
end
