class AddGroupIdToEvents < ActiveRecord::Migration[7.0]
  def up
    add_column :events, :group_id, :string
    Event.where.not(type: %i(KitAllocateEvent KitDeallocateEvent SnapshotEvent)).find_each do |event|
      # this is OK for now - it should still group together the right events.
      event.update_attribute(:group_id, "#{event.type}-#{event.eventable_id}")
    end

    SnapshotEvent.find_each do |event|
      event.update_attribute(:group_id, "snapshot-#{SecureRandom.hex}")
    end
    KitAllocateEvent.find_each do |event|
      event.update_attribute(:group_id, "kit-allocate-#{event.eventable_id}-#{SecureRandom.hex}")
    end
    KitDeallocateEvent.find_each do |event|
      event.update_attribute(:group_id, "kit-deallocate-#{event.eventable_id}-#{SecureRandom.hex}")
    end
  end

  def down
    remove_column :events, :group_id
  end
end
