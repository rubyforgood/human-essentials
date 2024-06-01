class DedupItemRequestsInRequests < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    Request.find_each do |request|
      grouped_item_requests = request.item_requests.to_a.group_by(&:item_id)

      grouped_item_requests.each do |item_id, item_requests|
        next if item_requests.size == 1

        Partners::ItemRequest.transaction do
          quantity = item_requests.map { |item_request| item_request.quantity.to_i }.sum.to_s
          children = item_requests.flat_map(&:children).uniq

          item_requests.first.update!(
            quantity: quantity,
            children: children
          )

          item_requests.drop(1).each(&:destroy!)
        end
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
