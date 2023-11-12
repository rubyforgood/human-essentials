class AddUserToEvents < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_reference :events, :user, index: { algorithm: :concurrently }
  end
end
