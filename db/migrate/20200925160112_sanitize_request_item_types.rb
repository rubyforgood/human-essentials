class SanitizeRequestItemTypes < ActiveRecord::Migration[6.0]
  def up
    Request.find_each do |request|
      request.send(:sanitize_items_data)
      request.save
    end
  end
end
