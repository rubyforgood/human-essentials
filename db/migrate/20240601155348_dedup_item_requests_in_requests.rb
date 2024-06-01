class DedupItemRequestsInRequests < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    Request.find_each do |request|
      grouped_item_requests = request.item_requests.to_a.group_by(&:item_id)

      Request.transaction do
        request_items = grouped_item_requests.map do |item_id, item_requests|
          quantity = item_requests.map { |item_request| item_request.quantity.to_i }.sum.to_s
          children = item_requests.flat_map(&:children).uniq

          primary_item_request = item_requests.shift

          # If item_requests isn't empty, then there were more
          # item_requests with that same item_id
          if !item_requests.empty?
            primary_item_request.update!(
              quantity: quantity,
              children: children
            )

            item_requests.each(&:destroy!)
          end

          {
            item_id: item_id,
            quantity: quantity
          }
        end

        request.update!(request_items: request_items)
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
