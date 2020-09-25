class SanitizeRequestItemTypes < ActiveRecord::Migration[6.0]
  def up
    Request.find_each do |request|
      request.request_items = request.request_items&.map do |item|
        item.merge("item_id" => item["item_id"]&.to_i, "quantity" => item["quantity"]&.to_i)
      end
      request.save
    end
  end
end
