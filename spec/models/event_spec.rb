RSpec.describe Event, type: :model do
  let(:organization) { FactoryBot.create(:organization) }
  describe '#most_recent_snapshot' do

    it 'should include the last usable snapshot' do
      freeze_time do
        snapshot1 = SnapshotEvent.create(organization_id: organization.id, event_time: 1.week.ago, updated_at: 1.week.ago)
        donation = DonationEvent.create(organization_id: organization.id, event_time: 3.days.ago, updated_at: 3.days.ago)
        snapshot2 = SnapshotEvent.create(organization_id: organization.id, event_time: 2.days.ago, updated_at: 2.days.ago)
        donation2 = DonationEvent.create(organization_id: organization.id, event_time: 1.minute.ago, updated_at: 1.minute.ago)

        expect(described_class.most_recent_snapshot(organization.id)).to eq(snapshot2)
      end
    end

    it 'should not include an unusable snapshot' do
      freeze_time do
        snapshot1 = SnapshotEvent.create(organization_id: organization.id, event_time: 1.week.ago, updated_at: 1.week.ago)
        donation = DonationEvent.create(organization_id: organization.id, event_time: 3.days.ago, updated_at: 1.hour.ago)
        snapshot2 = SnapshotEvent.create(organization_id: organization.id, event_time: 2.days.ago, updated_at: 2.days.ago)
        donation2 = DonationEvent.create(organization_id: organization.id, event_time: 1.minute.ago, updated_at: 1.minute.ago)

        expect(described_class.most_recent_snapshot(organization.id)).to eq(snapshot1)
      end

    end
  end

end
