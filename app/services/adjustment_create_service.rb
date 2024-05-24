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
        # Split into positive and negative portions.
        # N.B. -- THIS CHANGES THE ORIGINAL LINE ITEMS ON @adjustment DO **NOT** RESAVE AS THAT WILL CHANGE ANY NEGATIVE LINE ITEMS ON THE ADJUSTMENT TO POSITIVES
        increasing_adjustment, decreasing_adjustment = @adjustment.split_difference
        @adjustment.storage_location.increase_inventory(increasing_adjustment.line_item_values)
        @adjustment.storage_location.decrease_inventory(decreasing_adjustment.line_item_values)
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

    inventory_item = @adjustment.storage_location.inventory_items.find_by(item: line_item.item)
    if inventory_item.nil?
      @adjustment.errors.add(:inventory, "#{line_item.item.name} is not available to be removed from this storage location")
    elsif inventory_item.quantity < line_item.quantity * -1
      @adjustment.errors.add(:inventory, "The requested reduction of  #{line_item.quantity * -1} #{line_item.item.name}  items exceed the available inventory")
    end
  end
  @adjustment.errors.none?
end
