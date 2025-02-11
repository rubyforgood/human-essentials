class UpdateItemRequestNameForAll < ActiveRecord::Migration[7.2]
  def change
    return unless Rails.env.production?
    Item.all.each do |item|
      # Some very old item requests have nil partner keys.   We are not going to fix them with this.
      item_requests = Partners::ItemRequest.where(item_id: item.id).where.not(partner_key: nil).where.not(name: item.name)
      item_requests.each do |item_request|
        if(item_request.request)
          item_request.name = item.name
          item_request.save!
        end
      end
    end
  end
end
