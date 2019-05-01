class Request < ApplicationRecord; end
class ChangeStatusToEnumInRequests < ActiveRecord::Migration[5.2]
  def up
    add_column :requests, :status_new, :integer, default: 0

    Request.where(status: 'Active').update_all status_new: 0
    Request.where(status: 'Fulfilled').update_all status_new: 2

    remove_column :requests, :status

    rename_column :requests, :status_new, :status

    add_index :requests, :status
  end

  def down
    add_column :requests, :status_new, :string, default: 'Active'

    Request.where(status: 0).update_all status_new: 'Active'
    Request.where(status: 2).update_all status_new: 'Fulfilled'

    remove_column :requests, :status

    rename_column :requests, :status_new, :status

    add_index :requests, :status
  end
end
