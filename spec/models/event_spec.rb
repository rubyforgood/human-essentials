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
RSpec.describe Event, type: :model do
  let(:organization) { create(:organization) }

  describe "::types_for_select" do
    let(:a_event) { Class.new { def self.name = "AEvent" } }
    let(:z_event) { Class.new { def self.name = "ZEvent" } }

    before do
      allow(described_class).to receive(:descendants).and_return([z_event, a_event])
    end

    it "returns an array of ids and names" do
      results = described_class.types_for_select
      ids = results.map(&:id)
      names = results.map(&:name)

      expect(results.size).to eq(2)
      expect(ids).to eq(["AEvent", "ZEvent"])
      expect(names).to eq(["A", "Z"])
    end
  end

  describe "#most_recent_snapshot" do
    let(:eventable) { FactoryBot.create(:distribution, organization_id: organization.id) }
    let(:data) { EventTypes::Inventory.new(storage_locations: {}, organization_id: organization.id) }
    let(:payload) { EventTypes::InventoryPayload.new(items: []) }

    it "should include the last usable snapshot" do
      freeze_time do
        SnapshotEvent.create!(organization_id: organization.id, eventable: eventable,
          data: data,
          event_time: 1.week.ago, updated_at: 1.week.ago)
        DonationEvent.create!(organization_id: organization.id, eventable: eventable,
          data: payload,
          event_time: 3.days.ago, updated_at: 3.days.ago)
        snapshot2 = SnapshotEvent.create!(organization_id: organization.id, eventable: eventable,
          data: data,
          event_time: 2.days.ago, updated_at: 2.days.ago)
        DonationEvent.create!(organization_id: organization.id, eventable: eventable,
          data: payload,
          event_time: 1.minute.ago, updated_at: 1.minute.ago)

        expect(described_class.most_recent_snapshot(organization.id)).to eq(snapshot2)
      end
    end

    it "should not include an unusable snapshot" do
      freeze_time do
        snapshot1 = SnapshotEvent.create!(organization_id: organization.id, eventable: eventable,
          data: data,
          event_time: 1.week.ago, updated_at: 1.week.ago)
        DonationEvent.create!(organization_id: organization.id, eventable: eventable,
          data: payload,
          event_time: 3.days.ago, updated_at: 1.hour.ago)
        SnapshotEvent.create!(organization_id: organization.id, eventable: eventable,
          data: data,
          event_time: 2.days.ago, updated_at: 2.days.ago)
        DonationEvent.create!(organization_id: organization.id, eventable: eventable,
          data: payload,
          event_time: 1.minute.ago, updated_at: 1.minute.ago)

        expect(described_class.most_recent_snapshot(organization.id)).to eq(snapshot1)
      end
    end
  end
end
