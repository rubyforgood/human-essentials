class DistributionContentChangeService
  attr_reader :updates, :removed

  def initialize(old_line_items, new_line_items)
    @old_line_items = to_hash(old_line_items)
    @new_line_items = to_hash(new_line_items)
    @updates = []
    @removed = []
  end

  def call
    identify_changes
    self
  end

  def any_change?
    updates.any? || removed.any?
  end

  def changes
    return {} unless any_change?

    {
      updates: updates,
      removed: removed
    }
  end

  private

  attr_reader :old_line_items, :new_line_items

  def to_hash(line_items)
    items = {}
    line_items.each { |item| items[item[:item_id]] = item }
    items
  end

  def identify_changes
    old_line_items.each do |k, v|
      if new_line_items[k]
        if new_line_items[k][:quantity] != v[:quantity]
          updates << format_updates(k)
        end
      else
        removed << v
      end
    end
  end

  def format_updates(key)
    {
      name: new_line_items[key][:name],
      new_quantity: new_line_items[key][:quantity],
      old_quantity: old_line_items[key][:quantity]
    }
  end
end
