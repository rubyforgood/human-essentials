# Creates a veritable powerhouse.
# This module provides Duck Typed behaviors for anything that shuttle Items
# throughout the system. e.g. things that `has_many :line_items` -- this provides
# all the logic about how those kinds of things behave.
module Itemizable
  extend ActiveSupport::Concern

  included do
    # So we previously had `dependent:destroy` but that was deleting the `line_items`
    # before they could be also destroyed in the `storage_location`. This does the same
    # thing, but defers the deletion until after other stuff has been done.
    after_destroy do
      line_items.each(&:destroy)
    end

    has_many :line_items, as: :itemizable, inverse_of: :itemizable do
      def assign_insufficiency_errors(insufficiency_hash)
        insufficiency_hash = insufficiency_hash.index_by { |i| i[:item_id] }
        each do |line_item|
          next unless insufficiency = insufficiency_hash[line_item.item_id]

          line_item.errors.add(:quantity, :insufficient, message: "too high. Change to #{insufficiency[:quantity_on_hand]} or less")
        end
      end

      def combine!
        # Bail if there's nothing
        return if size.zero?

        # First we'll collect all the line_items that are used
        combined = {}
        parent_id = first.itemizable_id
        each do |line_item|
          next unless line_item.valid?
          next unless line_item.quantity != 0

          combined[line_item.item_id] ||= 0
          combined[line_item.item_id] += line_item.quantity
        end
        # Delete all the existing ones in this association -- this
        # method aliases to `delete_all`
        clear
        # And now recreate a new array of line_items using the corrected totals
        combined.each do |item_id, qty|
          build(quantity: qty, item_id: item_id, itemizable_id: parent_id)
        end
      end

      def quantities_by_category
        includes(:item).group("items.category").sum(:quantity)
      end

      def quantities_by_name
        results = {}
        each do |li|
          next if li.quantity.zero?

          results[li.id] = { item_id: li.item.id, name: li.item.name, quantity: li.quantity }
        end
        results
      end

      def sorted
        includes(:item).order("items.name")
      end

      def total
        sum(:quantity)
      end

      def total_value
        sum(&:value_per_line_item)
      end
    end
    has_many :items, through: :line_items
    accepts_nested_attributes_for :line_items,
                                  allow_destroy: true,
                                  reject_if: proc { |l| l[:item_id].blank? || l[:quantity].blank? }

    # Anything using line_items should not be OK with an invalid line_item
    validates_associated :line_items
  end

  def value_per_itemizable
    line_items.sum(&:value_per_line_item)
  end

  def to_a
    line_items.map do |l|
      # When the item isn't found, it's probably just inactive. This ensures it's available.
      item = Item.find(l.item_id)
      { item_id: item.id, name: item.name, quantity: l.quantity, active: item.active }.with_indifferent_access
    end
  end

  private

  # From Controller parameters
  def line_items_attributes(params)
    Array.wrap(params[:line_items_attributes]&.values)
  end

  def line_item_items_quantity_is_positive
    return if storage_location.nil?

    line_items.each do |line_item|
      next unless line_item.item

      next unless line_item.quantity <= 0

      errors.add(:inventory,
                 "#{line_item.item.name}'s quantity " \
                 "needs to be positive")
    end
  end

  def line_item_items_exist_in_inventory
    return if storage_location.nil?

    line_items.each do |line_item|
      next unless line_item.item

      inventory_item = storage_location.inventory_items.find_by(item: line_item.item)
      next unless inventory_item.nil?

      errors.add(:inventory,
                 "#{line_item.item.name} is not available " \
                 "at this storage location")
    end
  end
end
