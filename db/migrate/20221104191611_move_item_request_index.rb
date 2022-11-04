class MoveItemRequestIndex < ActiveRecord::Migration[7.0]
  def up
    if foreign_key_exists?(:item_requests, :partner_requests)
      remove_foreign_key :item_requests, :partner_requests
    end
    unless column_exists?(:item_requests, :old_partner_request_id, :integer)
      add_column :item_requests, :old_partner_request_id, :integer
    end
    sql = <<-SQL
      UPDATE item_requests
      SET old_partner_request_id=partner_request_id
      WHERE old_partner_request_id IS NULL
    SQL
    Partners::ItemRequest.connection.execute(sql)
    Partners::ItemRequest.find_each do |item_request|
      sql = <<-SQL
        SELECT * from partner_requests
        WHERE id=#{item_request.partner_request_id}
      SQL
      old_request = Partners::ItemRequest.connection.select_all(sql).to_a
      from = old_request[0]['updated_at'] - 10.seconds
      to = old_request[0]['updated_at'] + 10.seconds
      new_request = Request.where(partner_id: old_request[0]['partner_id']).
        where("UPDATED_AT BETWEEN '#{from.to_s(:db)}' AND '#{to.to_s(:db)}'").first
      item_request.update!(partner_request_id: new_request&.id)
    end
  end

  def down
    unless foreign_key_exists?(:item_requests, column: :partner_request_id)
      add_foreign_key :item_requests, :partner_requests, column: :partner_request_id
    end
    if column_exists?(:item_requests, :old_partner_request_id, :integer)
      remove_column :item_requests, :old_partner_request_id, :integer
    end
  end

end
