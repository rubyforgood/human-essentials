# H/T to http://www.justinweiss.com/articles/search-and-filter-rails-models-without-bloating-your-controller/

module Itemizable
	extend ActiveSupport::Concern

	included do
    has_many :line_items, as: :itemizable, inverse_of: :itemizable do
      def combine!
        # Bail if there's nothing
        return if self.size == 0
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
        combined.each do |item_id,qty|
          build(quantity: qty, item_id: item_id, itemizable_id: parent_id)
        end
      end

      def quantities_by_category
        includes(:item).group("items.category").sum(:quantity)
      end

      def sorted
        includes(:item).order("items.name")
      end

      def total
        self.sum(:quantity)
      end
    end
    has_many :items, through: :line_items
    accepts_nested_attributes_for :line_items,
      allow_destroy: true,
      :reject_if => proc { |li| li[:item_id].blank? || li[:quantity].blank? }

	end
  private

  def line_item_items_exist_in_inventory
    self.line_items.each do |line_item|
      next unless line_item.item
      inventory_item = self.storage_location.inventory_items.find_by(item: line_item.item)
      if inventory_item.nil?
        errors.add(:inventory,
                   "#{line_item.item.name} is not available " \
                   "at this storage location")
      end
    end
  end
end
