# Encapsulates methods that need some business logic
module ItemsHelper
  include MoneyRails::ActionViewExtension

  def dollar_presentation(value)
    dollars = cents_to_dollar(value)
    humanized_money_with_symbol(dollars)
  end

  def dollar_value(value)
    value.zero? ? '' : dollar_presentation(value)
  end

  def cents_to_dollar(value_in_cents)
    Money.new(value_in_cents).to_f
  end

  def selected_item_request_units(item)
    item_request_unit_names = item.persisted? ? item.request_units.pluck(:name) : []
    current_organization.request_units.select { |unit| item_request_unit_names.include?(unit.name) }.pluck(:id)
  end

  def quantity_below_minimum?(row_item)
    row_item[:quantity] < row_item[:item_on_hand_minimum_quantity]
  end
end
