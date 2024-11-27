class DedupItemRequestsInRequests < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    # There's some really gross request data in Jan 2023 and earlier
    # that we don't want to get swept up in this migration. We'll need
    # to fix it some day but for now we'll make recent-ish, well-formed
    # data obey the dedup requirement, which will reduce weird edge
    # cases when fulfilling requests + editing distributions.
    start_date = Date.new(2023, 6, 1)

    Request.where(created_at: start_date..).find_each do |request|
      grouped_item_requests = request.item_requests.to_a.group_by(&:item_id)

      if grouped_item_requests.values.all? { |item_requests| item_requests.length == 1 }
        next
      end

      Request.transaction do
        request_items = grouped_item_requests.map do |item_id, item_requests|
          if item_requests.length == 1
            next {
              item_id: item_id,
              quantity: item_requests.first.quantity
            }
          end

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

        request.reload.update!(request_items: request_items)
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
