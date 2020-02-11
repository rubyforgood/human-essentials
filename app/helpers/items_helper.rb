# Encapsulates methods that need some business logic
module ItemsHelper
  def dollar_value(value, addition = '')
    if value.zero?
      ''
    else
      addition + ActionController::Base.helpers.number_to_currency(cents_to_dollar(value), precision: cents_to_dollar(value).round == value ? 0 : 2)
    end
  end

  def cents_to_dollar(value_in_cents)
    value_in_cents.to_f / 100
  end
end
