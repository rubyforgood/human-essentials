class DistributionContentService
	attr_reader :updates, :removed

	def initialize(old_line_items, new_line_items)
    @old_line_items = to_hash(old_line_items)
		@new_line_items = to_hash(new_line_items)
		@updates = []
		@removed = []
	end

	def any_change?
		identify_changes
		!updates.empty? || !removed.empty?
	end

	private

	attr_reader :old_line_items, :new_line_items

	def to_hash(line_items)
		items = {}
		line_items.each { |item| items[item[:item_id]] = item }
		return items
	end

	def identify_changes
		old_line_items.each do |k, v|
      if new_line_items[k]
        if new_line_items[k][:quantity] != v[:quantity]
          updates << k
        end
      else
        removed << k
      end
    end
	end
end