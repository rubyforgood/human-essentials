class ClearEventsOnceAgain < ActiveRecord::Migration[7.0]
  def change
    safety_assured { execute('drop table inventory_discrepancies') }
    Event.delete_all
    Organization.all.each do |org|
      SnapshotEvent.publish(org)
    end
  end
end
