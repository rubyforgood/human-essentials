# Encapsulates methods that need some business logic
module ItemsHelper
  def dollar_presentation(value)
    dollars = cents_to_dollar value
    rounds_to_self = dollars.round == value
    precision = rounds_to_self ? 0 : 2

    ActionController::Base.helpers.number_to_currency dollars, precision: precision
  end

  def dollar_value(value, addition = '')
    if value.zero?
      ''
    else
      addition + dollar_presentation(value)
    end
  end

  def cents_to_dollar(value_in_cents)
    value_in_cents.to_f / 100
  end
end
