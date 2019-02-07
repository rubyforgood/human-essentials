module ItemsHelper
  def item_value(value, addition = '')
    if value.zero?
      ''
    else
      addition + ActionController::Base.helpers.number_to_currency(value, precision: value.round == value ? 0 : 2)
    end
  end
end