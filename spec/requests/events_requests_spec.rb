RSpec.describe "Events", type: :request do
  let(:organization) { create(:organization) }
  let(:user) { create(:organization_admin, organization: organization) }
  let(:storage_location) { create(:storage_location, organization: organization) }
  let(:storage_location2) { create(:storage_location, organization: organization) }
  let(:item) { create(:item, organization: organization, name: "Item1") }
  let(:item2) { create(:item, organization: organization, name: "Item2") }

  context "When signed in" do
    before { sign_in(user) }

    describe "GET #index" do
      let(:params) { {format: "html"} }

      subject do
        get events_path(params)
        response
      end

      before do
        donation = create(:donation, :with_items, storage_location: storage_location,
          organization: organization, item: item, item_quantity: 66)
        DonationEvent.publish(donation)
        donation2 = create(:donation, :with_items, storage_location: storage_location2,
          organization: organization, item: item, item_quantity: 77)
        DonationEvent.publish(donation2)
        donation3 = create(:donation, :with_items, storage_location: storage_location,
          organization: organization, item: item2, item_quantity: 55)
        DonationEvent.publish(donation3)
        adjustment = create(:adjustment, :with_items, storage_location: storage_location,
          organization: organization, item: item, item_quantity: 88)
        AdjustmentEvent.publish(adjustment)
        travel(-1.year) do
          donation = create(:donation, :with_items, item: item, organization: organization, item_quantity: 99)
          DonationEvent.publish(donation)
        end
      end

      it "should be successful" do
        subject
        expect(response.body).to include("Item1</a>")
        expect(response.body).to include("Item2</a>")
        expect(response.body).to include("55<br>")
        expect(response.body).to include("66<br>")
        expect(response.body).to include("77<br>")
        expect(response.body).to include("88<br>")
        expect(response.body).not_to include("99<br>")
      end

      it "should show deleted items on regular event without crashing" do
        deleted_item = create(:item, organization: organization)
        travel(-1.day) do
          SnapshotEvent.create!(
            eventable: organization,
            organization_id: organization.id,
            event_time: Time.zone.now,
            data: EventTypes::Inventory.new(
              organization_id: organization.id,
              storage_locations: {
                storage_location.id => EventTypes::EventStorageLocation.new(
                  id: storage_location.id,
                  items: {
                    item.id => EventTypes::EventItem.new(item_id: item.id, quantity: 0),
                    item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 0)
                  }
                ),
                storage_location2.id => EventTypes::EventStorageLocation.new(
                  id: storage_location2.id,
                  items: {
                    item.id => EventTypes::EventItem.new(item_id: item.id, quantity: 0),
                    item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 0)
                  }
                )
              }
            )
          )
          donation = create(:donation, organization: organization)
          DonationEvent.create!(
            eventable: donation,
            organization_id: organization.id,
            event_time: Time.zone.now,
            data: EventTypes::InventoryPayload.new(
              items: [
                EventTypes::EventLineItem.new(item_id: item.id,
                  quantity: 0,
                  item_value_in_cents: 5,
                  from_storage_location: nil,
                  to_storage_location: storage_location.id),
                EventTypes::EventLineItem.new(item_id: item2.id,
                  quantity: 0,
                  item_value_in_cents: 5,
                  from_storage_location: nil,
                  to_storage_location: storage_location.id),
                EventTypes::EventLineItem.new(item_id: deleted_item.id,
                  quantity: 0,
                  item_value_in_cents: 5,
                  from_storage_location: nil,
                  to_storage_location: storage_location.id)
                     ]
            )
          )
        end
        deleted_id = deleted_item.id
        deleted_item.destroy
        subject
        expect(response.body).to include("Item1</a>")
        expect(response.body).to include("Item2</a>")
        expect(response.body).to include("Item #{deleted_id} (deleted)")
      end

      it "should show deleted items on snapshot without crashing" do
        deleted_item = create(:item, organization: organization)
        travel(-1.day) do
          SnapshotEvent.create!(
            eventable: organization,
            organization_id: organization.id,
            event_time: Time.zone.now,
            data: EventTypes::Inventory.new(
              organization_id: organization.id,
              storage_locations: {
                storage_location.id => EventTypes::EventStorageLocation.new(
                  id: storage_location.id,
                  items: {
                    item.id => EventTypes::EventItem.new(item_id: item.id, quantity: 0),
                    item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 0),
                    deleted_item.id => EventTypes::EventItem.new(item_id: deleted_item.id, quantity: 0)
                  }
                ),
                storage_location2.id => EventTypes::EventStorageLocation.new(
                  id: storage_location2.id,
                  items: {
                    item.id => EventTypes::EventItem.new(item_id: item.id, quantity: 0),
                    item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 0),
                    deleted_item.id => EventTypes::EventItem.new(item_id: deleted_item.id, quantity: 0)
                  }
                )
              }
            )
          )
        end
        deleted_id = deleted_item.id
        deleted_item.destroy
        subject
        expect(response.body).to include("Item1</a>")
        expect(response.body).to include("Item2</a>")
        expect(response.body).to include("Item #{deleted_id} (deleted)")
      end

      context "with type filter" do
        let(:params) { {format: "html", filters: {by_type: "DonationEvent"}} }

        it "should not include the adjustment" do
          subject
          expect(response.body).to include("Item1</a>")
          expect(response.body).to include("Item2</a>")
          expect(response.body).to include("55<br>")
          expect(response.body).to include("66<br>")
          expect(response.body).to include("77<br>")
          expect(response.body).not_to include("88<br>")
          expect(response.body).not_to include("99<br>")
        end
      end

      context "with item filter" do
        let(:params) { {format: "html", filters: {by_item: item.id}} }

        it "should not include the other item" do
          subject
          expect(response.body).to include("Item1</a>")
          expect(response.body).not_to include("Item2</a>")
          expect(response.body).not_to include("55<br>")
          expect(response.body).to include("66<br>")
          expect(response.body).to include("77<br>")
          expect(response.body).to include("88<br>")
          expect(response.body).not_to include("99<br>")
        end
      end

      context "with storage location filter" do
        let(:params) { {format: "html", filters: {by_storage_location: storage_location.id}} }

        it "should not include the other storage location" do
          subject
          expect(response.body).to include("Item1</a>")
          expect(response.body).to include("Item2</a>")
          expect(response.body).to include("55<br>")
          expect(response.body).to include("66<br>")
          expect(response.body).not_to include("77<br>")
          expect(response.body).to include("88<br>")
          expect(response.body).not_to include("99<br>")
        end
      end

      context "with date filter" do
        let(:params) {
          {
            format: "html",
            filters: {filters: {
              date_range: date_range_picker_params(3.days.ago, Time.zone.tomorrow)
            }}
          }
        }

        it "should not include the old donation" do
          subject
          expect(response.body).to include("Item1</a>")
          expect(response.body).to include("Item2</a>")
          expect(response.body).to include("55<br>")
          expect(response.body).to include("66<br>")
          expect(response.body).to include("77<br>")
          expect(response.body).to include("88<br>")
          expect(response.body).not_to include("99<br>")
        end
      end

      context "with eventable_id" do
        let(:donation) do
          create(:donation, :with_items, item: item, organization: organization, item_quantity: 44)
        end
        let(:params) { {format: "html", eventable_id: donation.id, eventable_type: "Donation"} }
        before do
          DonationEvent.publish(donation)
          donation.line_items.first.quantity = 33
          DonationEvent.publish(donation) # an update
        end

        it "should only show events from that eventable" do
          subject
          expect(response.body).to include("Item1</a>")
          expect(response.body).to include("44<br>")
          expect(response.body).to include("33<br>")
          expect(response.body).not_to include("Item2</a>")
          expect(response.body).not_to include("55<br>")
          expect(response.body).not_to include("66<br>")
          expect(response.body).not_to include("77<br>")
          expect(response.body).not_to include("88<br>")
          expect(response.body).not_to include("99<br>")
        end
      end
    end
  end

  context "When not signed in" do
    let(:object) do
      donation = create(:donation)
      DonationEvent.publish(donation)
    end

    include_examples "requiring authorization"
  end
end
