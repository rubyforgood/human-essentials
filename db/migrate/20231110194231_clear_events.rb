class ClearEvents < ActiveRecord::Migration[7.0]
  def change
    InventoryDiscrepancy.delete_all
    Event.delete_all
    Organization.all.each do |org|
      SnapshotEvent.publish(org)
    end
  end
end
