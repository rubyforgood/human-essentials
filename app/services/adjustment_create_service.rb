# frozen_string_literal: true

class AdjustmentCreateService
  include ServiceObjectErrorsMixin
  attr_reader :adjustment

  def initialize(adjustment_or_params)
    @adjustment = if adjustment_or_params.is_a?(Adjustment)
      adjustment_or_params
    else
      Adjustment.new(adjustment_or_params)
    end
  end

  def call
    # Combine line items for adjustment
    combine_adjustment
    # Check for validity, and save the actual adjustment

    if @adjustment.valid? && enough_inventory_for_decreases?
      ActiveRecord::Base.transaction do
        # Make the necessary changes in the db
        @adjustment.save
        AdjustmentEvent.publish(adjustment)
      rescue Errors::InsufficientAllotment, InventoryError => e
        @adjustment.errors.add(:base, e.message)
        raise ActiveRecord::Rollback
      end
    end
    self
  end

  def combine_adjustment
    @adjustment.line_items.combine!
  end
end

def enough_inventory_for_decreases?
  return false if @adjustment.storage_location.nil?
  @adjustment.line_items.each do |line_item|
    next unless line_item.quantity.negative?
  end
  @adjustment.errors.none?
end
