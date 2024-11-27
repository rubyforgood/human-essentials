class ClearEventsWithFeeling < ActiveRecord::Migration[7.1]
  def change
    no_change_ids = [9, 33, 155]
    Event.where.not(organization_id: no_change_ids).delete_all
    Organization.where.not(id: no_change_ids).all.each do |org|
      SnapshotEvent.publish(org)
    end
  end
end
