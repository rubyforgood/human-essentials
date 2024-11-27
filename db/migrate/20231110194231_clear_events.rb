class ClearEvents < ActiveRecord::Migration[7.0]
  def change
    Event.delete_all
    Organization.all.each do |org|
      SnapshotEvent.publish(org)
    end
  end
end
