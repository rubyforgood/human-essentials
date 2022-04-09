module Deadlinable
  extend ActiveSupport::Concern

  MIN_DAY_OF_MONTH = 1
  MAX_DAY_OF_MONTH = 28

  included do
    validates :deadline_day, numericality: {only_integer: true, less_than_or_equal_to: MAX_DAY_OF_MONTH,
                                            greater_than_or_equal_to: MIN_DAY_OF_MONTH, allow_nil: true}
    validates :reminder_day, numericality: {only_integer: true, less_than_or_equal_to: MAX_DAY_OF_MONTH,
                                            greater_than_or_equal_to: MIN_DAY_OF_MONTH, allow_nil: true}

    validates :reminder_day, numericality: {other_than: :deadline_day}, if: :deadline_day?
  end
end
