# frozen_string_literal: true

class CreateEvents < ActiveRecord::Migration[7.0]

  disable_ddl_transaction!

  def change
    create_table :events do |t|
      t.string :type, null: false
      t.datetime :event_time, null: false, precision: 6
      t.jsonb :data
      t.bigint :eventable_id
      t.string :eventable_type

      t.timestamps
    end
    add_reference :events, :organization, index: {algorithm: :concurrently}
    add_index :events, [:organization_id, :event_time]
  end
end
