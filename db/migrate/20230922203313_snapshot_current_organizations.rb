class SnapshotCurrentOrganizations < ActiveRecord::Migration[7.0]
  def change
    Organization.all.each do |org|
      SnapshotEvent.publish(org)
    end
  end
end
