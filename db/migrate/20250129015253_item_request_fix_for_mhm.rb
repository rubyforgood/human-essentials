class ItemRequestFixForMhm < ActiveRecord::Migration[7.2]
  def change
    return unless Rails.env.production?
    item_ids = [302, 14372]
    item_ids.each do |item_id|
      item = Item.find(item_id)
      item_requests = Partners::ItemRequest.where(item_id: item_id)
      puts item_requests
      item_requests.each do |item_request|
        if(item_request.request)
          item_request.name = item.name
          item_request.save!
        end
      end
    end
  end

end
