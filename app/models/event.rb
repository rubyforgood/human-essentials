# == Schema Information
#
# Table name: events
#
#  id              :bigint           not null, primary key
#  data            :jsonb
#  event_time      :datetime         not null
#  eventable_type  :string
#  type            :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  eventable_id    :bigint
#  group_id        :string
#  organization_id :bigint
#  user_id         :bigint
#
class Event < ApplicationRecord
  include Filterable
  scope :for_organization, ->(organization_id) { where(organization_id: organization_id).order(:event_time, :updated_at) }
  scope :without_snapshots, -> { where("type != 'SnapshotEvent'") }
  scope :during, ->(range) { where(events: {created_at: range}) }
  scope :by_type, ->(type) { where(type: type) }
  scope :by_item, ->(item_id) {
    joins("left join lateral jsonb_array_elements(data->'items') AS item ON true")
      .where("type = 'SnapshotEvent' OR (item->>'item_id')=? ", item_id)
  }
  scope :by_storage_location, ->(loc_id) {
    joins("left join lateral jsonb_array_elements(data->'items') AS item ON true")
      .where("type = 'SnapshotEvent' OR (item->>'from_storage_location')=? OR (item->>'to_storage_location')=?", loc_id, loc_id)
  }

  serialize :data, coder: EventTypes::StructCoder.new(EventTypes::InventoryPayload)

  belongs_to :eventable, polymorphic: true
  belongs_to :user, optional: true
  belongs_to :organization

  before_create do
    self.user_id = PaperTrail.request&.whodunnit
  end
  after_create :validate_inventory

  # @return [Array<OpenStruct>]
  def self.types_for_select
    descendants.map { |klass|
      OpenStruct.new(name: klass.name.sub("Event", "").titleize, value: klass.name)
    }.sort_by(&:name)
  end

  # Returns the most recent "usable" snapshot. A snapshot is unusable if there is another event
  # that was originally made before the snapshot, but was later updated/edited after the snapshot
  # (i.e. there is a correction event whose event_time is before the snapshot, but whose
  # updated_at time is after it).
  # In this case, the values in the snapshot can't be used to start the inventory because they
  # wouldn't reflect the updates.
  # There should always be at least one usable snapshot since the very first event we have in the
  # DB for any organization should be a SnapshotEvent.
  # @param organization_id [Integer]
  # @return [SnapshotEvent]
  def self.most_recent_snapshot(organization_id)
    query = <<-SQL
        select *
        FROM events as snapshots
        WHERE type='SnapshotEvent' AND organization_id=$1
        AND NOT EXISTS (
            SELECT id
            FROM events
            WHERE type != 'SnapshotEvent'
            AND event_time < snapshots.event_time AND updated_at > snapshots.event_time
        )
        ORDER BY event_time DESC
        LIMIT 1
    SQL
    SnapshotEvent.find_by_sql(query, [organization_id]).first
  end

  def self.read_events?(organization)
    Flipper.enabled?(:read_events, organization)
  end

  def validate_inventory
    return unless Event.read_events?(organization)

    InventoryAggregate.inventory_for(organization_id, validate: true)
  rescue InventoryError => e
    item = Item.find_by(id: e.item_id)&.name || "Item ID #{e.item_id}"
    loc = StorageLocation.find_by(id: e.storage_location_id)&.name || "Storage Location ID #{e.storage_location_id}"
    e.message << " for #{item} in #{loc}"
    if e.event != self
      e.message.prepend("Error occurred when re-running events: #{e.event.type} on #{e.event.created_at.to_date}: ")
      e.message << " Please contact the Human Essentials admin staff for assistance."
    end
    raise e
  end
end
