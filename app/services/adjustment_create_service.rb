# frozen_string_literal: true

class AdjustmentCreateService
  include ServiceObjectErrorsMixin
  attr_reader :adjustment

  def initialize(adjustment_params)
    @adjustment = Adjustment.new(adjustment_params)
  end

  def call
    # Combine line items for adjustment
    combine_adjustment
    # Check for validity, and save the actual adjustment

    if @adjustment.valid? && enough_inventory_for_decreases?
      ActiveRecord::Base.transaction do
        # Make the necessary changes in the db
        @adjustment.save
        # Split into positive and negative portions.  NOTE -- THIS CHANGES THE ORIGINAL LINE ITEMS DO **NOT** RESAVE
        increasing_adjustment, decreasing_adjustment = @adjustment.split_difference
        @adjustment.storage_location.increase_inventory increasing_adjustment
        @adjustment.storage_location.decrease_inventory decreasing_adjustment
      rescue InsufficientAllotment => e
        @adjustment.errors.add(:base, e.message)
        raise e
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
  return true if @adjustment.errors.none?
  false
end
