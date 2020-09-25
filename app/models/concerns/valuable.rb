module Valuable
  extend ActiveSupport::Concern

  included do
    validates :value_in_cents, numericality: { greater_than_or_equal_to: 0 }
  end

  def value_in_dollars
    value_in_cents.to_d / 100
  end

  def value_in_dollars=(dollars)
    self.value_in_cents = dollars.to_d * 100
  end
end
