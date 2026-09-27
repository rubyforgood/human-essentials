RSpec.describe "Events", type: :request do
  let(:organization) { create(:organization) }
  let(:user) { create(:organization_admin, organization: organization) }
  let(:storage_location) { create(:storage_location, organization: organization) }
  let(:storage_location2) { create(:storage_location, organization: organization) }
  let(:item) { create(:item, organization: organization, name: "Item1") }
  let(:item2) { create(:item, organization: organization, name: "Item2") }

  # Returns the table row for the given event type as a CSV-like mapping of
  # header names to their <td> cells, e.g. row["From Location"].
  def row_cells(event_type)
    doc = Nokogiri::HTML(response.body)
    headers = doc.css("thead th").map(&:text)
    row = doc.css("tbody tr").find do |r|
      r.css("td")[1]&.text&.strip == event_type
    end
    return nil unless row

    row.css("td").each_with_index.each_with_object({}) do |(cell, index), cells|
      cells[headers[index]] = cell
    end
  end

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

      it "renders kit allocation events linking to the kit" do
        content_item = create(:item, organization: organization, name: "KitContent")
        kit = create_kit(organization: organization, line_items_attributes: [{item_id: content_item.id, quantity: 1}])
        TestInventory.create_inventory(organization, {storage_location.id => {content_item.id => 10}})
        KitAllocateEvent.publish(kit, storage_location.id, 2)

        subject
        expect(response).to be_successful
        expect(response.body).to include(kit_path(kit.id))
      end

      it "should show items in alphabetical order" do
        item_1 = create(:item, organization: organization, name: "Zebra")
        item_2 = create(:item, organization: organization, name: "apple")
        item_3 = create(:item, organization: organization, name: "Monkey")

        donation = create(:donation, :with_items, organization: organization,
          storage_location: storage_location, item: item_1, item_quantity: 1)
        create(:line_item, item: item_2, quantity: 1, itemizable: donation)
        create(:line_item, item: item_3, quantity: 1, itemizable: donation)

        DonationEvent.publish(donation)

        get events_path(filters: {by_type: "DonationEvent", date_range: date_range_picker_params(3.days.ago, Time.zone.tomorrow)})

        td_with_items = Nokogiri::HTML(response.body).css("td").find do |td|
          td.inner_html.include?("/items/")
        end

        expect(td_with_items).not_to be_nil

        links = td_with_items.css("a").map(&:text)
        expect(links).to eq(links.sort_by(&:downcase))
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
          donation = create(:donation, organization: organization, created_at: 1.day.from_now)
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
            filters: {
              date_range: date_range_picker_params(3.days.ago, Time.zone.tomorrow)
            }
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
          # should not be affected by the date range
          travel(-1.year) do
            DonationEvent.publish(donation)
            donation.line_items.first.quantity = 33
            DonationEvent.publish(donation) # an update
          end
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

      context "with kit allocation and deallocation events" do
        let(:component_item) { create(:item, organization: organization, name: "Widget") }
        let(:kit) do
          create_kit(organization: organization, line_items_attributes: [
            {item_id: component_item.id, quantity: 5}
          ])
        end

        before do
          TestInventory.create_inventory(organization, {
            storage_location.id => {component_item.id => 100}
          })
          KitAllocateEvent.publish(kit, storage_location.id, 3)
          KitDeallocateEvent.publish(kit, storage_location.id, 1)
        end

        it "shows a positive kit quantity to the storage location and a negative item quantity for KitAllocate" do
          subject
          row = row_cells("KitAllocate")
          expect(row).not_to be_nil
          expect(row["From Location"].text).not_to include(storage_location.name)
          expect(row["To Location"].text).to include(storage_location.name)
          expect(row["Items"].text).to include("#{kit.name}: 3")
          expect(row["Items"].text).to include("Widget: -15")
        end

        it "shows a positive kit quantity from the storage location and a negative item quantity for KitDeallocate" do
          subject
          row = row_cells("KitDeallocate")
          expect(row).not_to be_nil
          expect(row["From Location"].text).to include(storage_location.name)
          expect(row["To Location"].text).not_to include(storage_location.name)
          expect(row["Items"].text).to include("#{kit.name}: 1")
          expect(row["Items"].text).to include("Widget: -5")
        end
      end

      context "with kit events whose line items are not in the usual order" do
        # KitAllocateEvent/KitDeallocateEvent normally append the kit's own line item
        # last, but the view must not depend on that ordering to work out direction.
        let(:component_item) { create(:item, organization: organization, name: "Widget") }
        let(:kit) do
          create_kit(organization: organization, line_items_attributes: [
            {item_id: component_item.id, quantity: 5}
          ])
        end

        before do
          TestInventory.create_inventory(organization, {
            storage_location.id => {component_item.id => 100, kit.id => 100}
          })
        end

        it "shows the correct direction for KitAllocate with the kit's line item first" do
          KitAllocateEvent.create!(
            eventable: kit,
            organization_id: organization.id,
            event_time: Time.zone.now,
            data: EventTypes::InventoryPayload.new(
              items: KitAllocateEvent.event_line_items(kit, storage_location.id, 2).reverse
            )
          )
          subject
          row = row_cells("KitAllocate")
          expect(row).not_to be_nil
          expect(row["From Location"].text).not_to include(storage_location.name)
          expect(row["To Location"].text).to include(storage_location.name)
          expect(row["Items"].text).to include("#{kit.name}: 2")
          expect(row["Items"].text).to include("Widget: -10")
        end

        it "shows the correct direction for KitDeallocate with the kit's line item first" do
          KitDeallocateEvent.create!(
            eventable: kit,
            organization_id: organization.id,
            event_time: Time.zone.now,
            data: EventTypes::InventoryPayload.new(
              items: KitDeallocateEvent.event_line_items(kit, storage_location.id, 4).reverse
            )
          )
          subject
          row = row_cells("KitDeallocate")
          expect(row).not_to be_nil
          expect(row["From Location"].text).to include(storage_location.name)
          expect(row["To Location"].text).not_to include(storage_location.name)
          expect(row["Items"].text).to include("#{kit.name}: 4")
          expect(row["Items"].text).to include("Widget: -20")
        end
      end
    end
  end
end
