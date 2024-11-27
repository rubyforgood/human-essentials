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
    value_in_cents.to_f / 100
  end

  def selected_item_request_units(item)
    item_request_unit_names = item.persisted? ? item.request_units.pluck(:name) : []
    current_organization.request_units.select { |unit| item_request_unit_names.include?(unit.name) }.pluck(:id)
  end
end
