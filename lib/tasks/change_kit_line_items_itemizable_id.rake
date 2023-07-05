desc "change the itemizable_id for all kits' line items to kit.item.id"
task change_itemizable_id: :environment do
  line_items = LineItem.where(itemizable_type: "Kit")
  puts "Total line_items: #{line_items.count}"

  line_items.each do |line_item|
    puts "Processing line_item with id: #{line_item.id}"
    item = line_item.itemizable.item
    line_item.itemizable = item
    line_item.save!
  end

  puts "Done..."
end
