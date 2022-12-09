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
    ApplicationRecord.connection.execute(sql)
    sql = <<-SQL
      select id, created_at, partner_id from partner_requests 
      ORDER BY created_at DESC
    SQL
    rows = ApplicationRecord.connection.select_all(sql)
    rows.each do |request|
      from = request['created_at'] - 10.seconds
      to = request['created_at'] + 10.seconds
      new_partner = Partners::Profile.find_by_id(request['partner_id'])&.partner_id
      next if new_partner.nil?

      new_request = Request.where(partner_id: new_partner).
        where("CREATED_AT BETWEEN '#{from.to_fs(:db)}' AND '#{to.to_fs(:db)}'").first
      next if new_request.nil?

      Partners::ItemRequest.where(old_partner_request_id: request['id']).
        update_all(partner_request_id: new_request.id, updated_at: Time.zone.now)
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
