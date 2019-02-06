module ItemsHelper
  def item_price(price, addition = '')
    if price.zero?
      ''
    else
      addition + number_to_currency(price, precision: price.round == price ? 0 : 2)
    end
  end
end