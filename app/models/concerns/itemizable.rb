# H/T to http://www.justinweiss.com/articles/search-and-filter-rails-models-without-bloating-your-controller/

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
      def combine!
        # Bail if there's nothing
        return if size.zero?
        # First we'll collect all the line_items that are used
        combined = {}
        parent_id = first.itemizable_id
        each do |i|
          next unless i.valid?
          combined[i.item_id] ||= 0
          combined[i.item_id] += i.quantity
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
    end
    has_many :items, through: :line_items
    accepts_nested_attributes_for :line_items,
                                  allow_destroy: true,
                                  reject_if: proc { |l| l[:item_id].blank? || l[:quantity].blank? }

    # Anything using line_items should not be OK with an invalid line_item
    validates_associated :line_items
  end

  def line_items_quantities
    line_items.inject(Hash.new) do |hash, line_item|
      hash[line_item.id] = OpenStruct.new(quantity: line_item.quantity, item_id: line_item.item_id)
      hash
    end
  end

  private

  def line_item_items_exist_in_inventory
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
