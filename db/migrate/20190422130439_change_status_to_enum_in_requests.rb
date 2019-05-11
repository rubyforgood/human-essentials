# Fix to ensure that the object is available in the migration
class Request < ApplicationRecord; end

# We're changing our state-tracking to Enums because it just makes more sense to do it that way
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
