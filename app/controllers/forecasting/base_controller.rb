class Forecasting::BaseController < ApplicationController
  def series(type)
    items = []

    current_organization.items.sort.each do |item|
      next if item.line_items.where(itemizable_type: type, item: item).blank?

      dates = Hash.new

      (1..Time.zone.today.month).each do |month|
        dates[month] = 0
      end

      total_items(item.line_items, type).each do |line_item|
        month = line_item.dig(0).to_date.month
        dates[month] = line_item.dig(1)
      end

      items << { name: item.name, data: dates.values }
    end

    items.sort_by { |hsh| hsh[:name] }
  end

  private

  def total_items(line_items, type)
    line_items.where(itemizable_type: type)
              .group_by_month(:created_at)
              .sum(:quantity)
  end
end
