RSpec.describe "StorageLocations", type: :request do
  include ActionView::Helpers::NumberHelper

  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:organization_admin) { create(:organization_admin, organization: organization) }

  context "While signed in" do
    before do
      sign_in(user)
    end

    describe "GET #index" do
      let!(:storage_location) do
        create(:storage_location,
          name: "Test Storage Location",
          address: "123 Donation Site Way",
          warehouse_type: StorageLocation::WAREHOUSE_TYPES.first,
          square_footage: 100)
      end
      let!(:storage_location2) do
        create(:storage_location,
          name: "Test Storage Location 1",
          address: "123 Donation Site Way",
          warehouse_type: StorageLocation::WAREHOUSE_TYPES.first,
          square_footage: 100)
      end

      context "html" do
        let(:response_format) { 'html' }

        it "succeeds" do
          get storage_locations_path(format: response_format)
          expect(response).to be_successful
        end

        it "displays grand total across storage locations" do
          item1 = create(:item, name: "Item A", value_in_cents: 100)
          item2 = create(:item, name: "Item B", value_in_cents: 200)

          TestInventory.create_inventory(storage_location.organization,
            { storage_location.id => { item1.id => 2, item2.id => 1 } })
          TestInventory.create_inventory(storage_location2.organization,
            { storage_location2.id => { item1.id => 3 } })
          get storage_locations_path(format: response_format)
          page = Nokogiri::HTML(response.body)

          total_row = page.at("table tbody tr:last-child")
          total_inventory = total_row.css("td.text-right")[0].text.strip
          total_value = total_row.css("td.text-right")[1].text.strip

          expect(total_inventory).to eq("6")
          expect(total_value).to eq("$7.00")
        end

        context "with inactive locations" do
          let!(:discarded_storage_location) { create(:storage_location, name: "Some Random Location", discarded_at: rand(10.years).seconds.ago) }

          it "does not includes the inactive location" do
            get storage_locations_path(format: response_format)
            expect(response.body).to_not include(discarded_storage_location.name)
          end

          context "with include_inactive_locations" do
            it "includes the inactive location" do
              get storage_locations_path(include_inactive_storage_locations: "1", format: response_format)
              expect(response.body).to include(discarded_storage_location.name)
            end
          end
        end

        context "with empty storage location" do
          it "shows a deactivate button" do
            get storage_locations_path(format: response_format)
            page = Nokogiri::HTML(response.body)
            deactivate_link = page.at_css("form[action='#{storage_location_deactivate_path(storage_location)}'] button")
            expect(deactivate_link.attr("class")).not_to match(/disabled/)
          end
        end

        context "with nonempty storage location" do
          before do
            TestInventory.create_inventory(storage_location.organization,
              { storage_location.id => { create(:item, name: "A").id => 1 } })
          end

          it "shows a disabled deactivate button" do
            get storage_locations_path(format: response_format)
            page = Nokogiri::HTML(response.body)
            deactivate_link = page.at_css("form[action='#{storage_location_deactivate_path(storage_location)}'] button")
            expect(deactivate_link.attr("class")).to match(/disabled/)
          end
        end
      end

      context "csv" do
        let(:response_format) { 'csv' }

        let(:storage_location_with_duplicate_item) {
          create(:storage_location,
            name: "Storage Location with Duplicate Items",
            address: "1500 Remount Road, Front Royal, VA 22630",
            warehouse_type: StorageLocation::WAREHOUSE_TYPES.first,
            square_footage: 100)
        }
        let(:storage_location_with_items) {
          create(:storage_location,
            name: "Storage Location with Items",
            address: "123 Donation Site Way",
            warehouse_type: StorageLocation::WAREHOUSE_TYPES.first,
            square_footage: 100)
        }
        let(:storage_location_with_unique_item) {
          create(:storage_location,
            name: "Storage Location with Unique Items",
            address: "Smithsonian Conservation Center new",
            warehouse_type: StorageLocation::WAREHOUSE_TYPES.first,
            square_footage: 100)
        }
        let(:item1) { create(:item, name: 'A') }
        let(:item2) { create(:item, name: 'B') }
        let(:item3) { create(:item, name: 'C') }
        let(:item4) { create(:item, name: 'D') }
        let!(:inactive_item) { create(:item, name: 'inactive item', active: false) }

        before do
          TestInventory.create_inventory(storage_location_with_items.organization, {
            storage_location_with_items.id => {
              item1.id => 1,
              item2.id => 1,
              item3.id => 1
            },
            storage_location_with_duplicate_item.id => {
              item3.id => 1
            },
            storage_location_with_unique_item.id => {
              item4.id => 5
            }
          })
        end

        it "succeeds" do
          get storage_locations_path(format: response_format)
          expect(response).to be_successful
        end

        it "includes headers followed by alphabetized item names" do
          storage_location_with_items = create(:storage_location)
          Item.delete_all
          item1 = create(:item, name: 'C')
          item2 = create(:item, name: 'B')
          item3 = create(:item, name: 'A')
          create(:item, name: 'inactive item', active: false)
          storage_location_with_duplicate_item = create(:storage_location)

          TestInventory.create_inventory(storage_location_with_items.organization, {
            storage_location_with_items.id => {
              item1.id => 1,
              item2.id => 1,
              item3.id => 1
            },
            storage_location_with_duplicate_item.id => {
              item3.id => 1
            }
          })
          get storage_locations_path(format: response_format)

          expect(response.body.split("\n")[0]).to eq([StorageLocation.csv_export_headers, item3.name, item2.name, item1.name, 'inactive item'].join(','))
        end

        it "Generates csv with Storage Location fields, alphabetized item names, item quantities lined up in their columns, and zeroes for no inventory" do
          get storage_locations_path(format: response_format)
          # The first address below is quoted since it contains commas
          csv = <<~CSV
            Name,Address,Square Footage,Warehouse Type,Total Inventory,Fair Market Value,A,B,C,D,inactive item
            Storage Location with Duplicate Items,"1500 Remount Road, Front Royal, VA 22630",100,Residential space used,1,0.0,0,0,1,0,0
            Storage Location with Items,123 Donation Site Way,100,Residential space used,3,0.0,1,1,1,0,0
            Storage Location with Unique Items,Smithsonian Conservation Center new,100,Residential space used,5,0.0,0,0,0,5,0
            Test Storage Location,123 Donation Site Way,100,Residential space used,0,0.0,0,0,0,0,0
            Test Storage Location 1,123 Donation Site Way,100,Residential space used,0,0.0,0,0,0,0,0
          CSV
          expect(response.body).to eq(csv)
        end

        context "when include inactive storage locations checkbox is checked" do
          let(:inactive_storage_location) {
            create(
              :storage_location,
              name: "Inactive Storage Location",
              address: "123 Donation Site Way",
              warehouse_type: StorageLocation::WAREHOUSE_TYPES.first,
              discarded_at: 5.months.ago,
              square_footage: 100
            )
          }

          before do
            TestInventory.create_inventory(
              inactive_storage_location.organization, {
                inactive_storage_location.id => {
                  item1.id => 1,
                  item2.id => 1,
                  item3.id => 1
                }
              }
            )
          end

          it "generates csv with Storage Locations that are inactive" do
            get storage_locations_path(include_inactive_storage_locations: "1", format: response_format)

            csv = <<~CSV
              Name,Address,Square Footage,Warehouse Type,Total Inventory,Fair Market Value,A,B,C,D,inactive item
              Inactive Storage Location,123 Donation Site Way,100,Residential space used,3,0.0,1,1,1,0,0
              Storage Location with Duplicate Items,"1500 Remount Road, Front Royal, VA 22630",100,Residential space used,1,0.0,0,0,1,0,0
              Storage Location with Items,123 Donation Site Way,100,Residential space used,3,0.0,1,1,1,0,0
              Storage Location with Unique Items,Smithsonian Conservation Center new,100,Residential space used,5,0.0,0,0,0,5,0
              Test Storage Location,123 Donation Site Way,100,Residential space used,0,0.0,0,0,0,0,0
              Test Storage Location 1,123 Donation Site Way,100,Residential space used,0,0.0,0,0,0,0,0
            CSV

            expect(response.body).to eq(csv)
          end
        end
      end
    end

    describe "GET #new" do
      it "returns http success" do
        get new_storage_location_path
        expect(response).to be_successful
      end
    end

    describe "GET #edit" do
      it "returns http success" do
        get edit_storage_location_path(id: create(:storage_location, organization: organization))
        expect(response).to be_successful
      end
    end

    describe "POST #import_csv" do
      let(:model_class) { StorageLocation }

      context "with a csv file" do
        let(:file) { fixture_file_upload("#{model_class.name.underscore.pluralize}.csv", "text/csv") }
        subject { post import_csv_storage_locations_path, params: { file: file } }

        it "invokes .import_csv" do
          expect(model_class).to respond_to(:import_csv).with(2).arguments
        end

        it "redirects" do
          subject
          expect(response).to be_redirect
        end

        it "presents a flash notice message" do
          subject
          expect(response).to have_notice "#{model_class.name.underscore.humanize.pluralize} were imported successfully!"
        end
      end

      context "without a csv file" do
        subject { post import_csv_storage_locations_path }

        it "redirects to :index" do
          subject
          expect(response).to be_redirect
        end

        it "presents a flash error message" do
          subject
          expect(response).to have_error "No file was attached!"
        end
      end

      context "csv file with wrong headers" do
        let(:file) { fixture_file_upload("wrong_headers.csv", "text/csv") }
        subject { post import_csv_storage_locations_path, params: { file: file } }

        it "redirects" do
          subject
          expect(response).to be_redirect
        end

        it "presents a flash error message" do
          subject
          expect(response).to have_error "Check headers in file!"
        end
      end
    end

    describe "POST #import_inventory" do
      context "when inventory already has items" do
        it "redirects with an error message" do
          item1 = create(:item)
          item2 = create(:item)
          item3 = create(:item)
          storage_location_with_items = create(:storage_location, organization: organization)
          TestInventory.create_inventory(organization,
            {
              storage_location_with_items.id => {
                item1.id => 30,
                item2.id => 10,
                item3.id => 40
              }
            })
          file = fixture_file_upload("inventory.csv", "text/csv")

          params = { file: file, storage_location: storage_location_with_items.id }
          post import_inventory_storage_locations_path, params: params

          expect(response).to be_redirect
          expect(response).to have_error "Could not complete action: inventory already has items stored"
        end
      end
    end

    describe "GET #show" do
      let(:item) { create(:item, name: "Test Item") }
      let(:item2) { create(:item, name: "Test Item2") }
      let(:item3) { create(:item, name: "Test Item3", active: false) }

      let(:storage_location) { create(:storage_location, name: "Test Storage Location", organization: organization) }
      before(:each) do
        TestInventory.create_inventory(storage_location.organization, {
          storage_location.id => {
            item.id => 200,
            item2.id => 0
          }
        })
      end

      context "html" do
        let(:response_format) { 'html' }

        it "selects the Inventory tab, or the Inventory Flow tab when asked for" do
          get storage_location_path(storage_location, format: response_format)
          tabs = Nokogiri::HTML(response.body)
          expect(tabs.at_css("#custom-tabs-inventory-tab")["aria-selected"]).to eq("true")
          expect(tabs.at_css("#custom-tabs-inventory-flow-tab")["aria-selected"]).to eq("false")

          get storage_location_path(storage_location, format: response_format, tab: "flow")
          tabs = Nokogiri::HTML(response.body)
          expect(tabs.at_css("#custom-tabs-inventory-tab")["aria-selected"]).to eq("false")
          expect(tabs.at_css("#custom-tabs-inventory-flow-tab")["aria-selected"]).to eq("true")
        end

        it "loads the Inventory Flow table lazily, keeping each tab's filter when the other is submitted" do
          date_range = "January 1, 2026 - January 31, 2026"
          get storage_location_path(storage_location, format: response_format, tab: "flow", version_date: "2026-01-15",
            filters: {date_range: date_range})
          page = Nokogiri::HTML(response.body)

          frame = page.at_css("turbo-frame#inventory_flow")
          expect(frame["loading"]).to eq("lazy")
          # links in the table (to items) navigate the whole page, not the frame
          expect(frame["target"]).to eq("_top")
          expect(Rack::Utils.parse_nested_query(URI(frame["src"]).query)).to eq("filters" => {"date_range" => date_range})
          expect(page.at_css("#custom-tabs-inventory form input[name='filters[date_range]']")["value"]).to eq(date_range)
          expect(page.at_css("#custom-tabs-inventory-flow form input[name='version_date']")["value"]).to eq("2026-01-15")
          expect(page.at_css("#custom-tabs-inventory-flow form input[name='tab']")["value"]).to eq("flow")
        end

        it "does not build the Inventory Flow table until the tab loads it" do
          expect(ItemsFlowQuery).not_to receive(:new)

          get storage_location_path(storage_location, format: response_format, tab: "flow")

          expect(response).to be_successful
          expect(Nokogiri::HTML(response.body).at_css("turbo-frame#inventory_flow tbody")).to be_nil
        end

        it "ignores a malformed filters param" do
          get storage_location_path(storage_location, format: response_format, filters: "x")

          expect(response).to be_successful
          expect(Nokogiri::HTML(response.body).at_css("turbo-frame#inventory_flow")["src"])
            .to eq(inventory_flow_storage_location_path(storage_location))
        end

        it "clears the Inventory Flow date range without leaving the tab or losing the inventory date" do
          get storage_location_path(storage_location, format: response_format, tab: "flow", version_date: "2026-01-15",
            filters: {date_range: "January 1, 2026 - January 31, 2026"})

          clear_link = Nokogiri::HTML(response.body).css("#custom-tabs-inventory-flow a").find { |a| a.text.include?("Clear Filters") }
          expect(clear_link["href"]).to eq(storage_location_path(storage_location, tab: "flow", version_date: "2026-01-15"))
        end

        it "should return a correct response" do
          get storage_location_path(storage_location, format: response_format)
          expect(response).to be_successful
          expect(response.body).to include("Test Storage Location")
          expect(response.body).to include("Test Item")
          expect(response.body).to include("Test Item2")
          expect(response.body).not_to include("Test Item3")
          expect(response.body).to include("200")
        end

        it "should return a correct response with empty version date param" do
          get storage_location_path(storage_location, format: response_format,
            version_date: '')
          expect(response).to be_successful
          expect(response.body).to include("Test Storage Location")
          expect(response.body).to include("Test Item")
          expect(response.body).to include("Test Item2")
          expect(response.body).not_to include("Test Item3")
          expect(response.body).to include("200")
        end

        context "with version date set" do
          let!(:inventory_item) {
            InventoryItem.create!(storage_location_id: storage_location.id,
              item_id: item.id,
              quantity: 200)
          }

          # @return [String] the item's quantity in the Inventory tab's table
          def inventory_tab_quantity(item)
            row = Nokogiri::HTML(response.body).css("#custom-tabs-inventory tbody tr")
              .find { |tr| tr.at_css("td").text.strip == item.name }
            row.css("td")[1].text.strip
          end

          context "before active events", versioning: true do
            it "should show the version specified" do
              travel 1.day do
                inventory_item.update!(quantity: 100)
              end
              travel 1.week do
                inventory_item.update!(quantity: 300)
              end
              travel 8.days do
                SnapshotEvent.delete_all
                SnapshotEvent.publish(organization)
              end
              travel 2.weeks do
                get storage_location_path(storage_location, format: response_format,
                  version_date: 9.days.ago.to_date.to_fs(:db))
                expect(response).to be_successful
                expect(response.body).to include("Test Storage Location")
                expect(inventory_tab_quantity(item)).to eq("100")
              end
            end
          end

          context "with active events" do
            it 'should show the right version' do
              SnapshotEvent.publish(organization)
              travel 1.day do
                TestInventory.create_inventory(organization, {
                  storage_location.id => {
                    item.id => 100,
                    item2.id => 0
                  }
                })
              end
              travel 1.week do
                TestInventory.create_inventory(organization, {
                  storage_location.id => {
                    item.id => 300,
                    item2.id => 0
                  }
                })
              end

              travel 2.weeks do
                get storage_location_path(storage_location, format: response_format,
                  version_date: 9.days.ago.to_date.to_fs(:db))
                expect(response).to be_successful
                expect(response.body).to include("Test Storage Location")
                expect(inventory_tab_quantity(item)).to eq("100")
              end
            end
          end
        end

        it "should include the inventory total market value" do
          get storage_location_path(storage_location, format: response_format)
          expect(response).to be_successful
          expect(response.body).to include(number_to_currency(storage_location.inventory_total_value_in_dollars))
        end
      end

      context "csv" do
        let(:response_format) { 'csv' }

        it "should be successful" do
          get storage_location_path(storage_location, format: response_format)
          expect(response).to be_successful
        end
      end
    end

    describe "GET #inventory_flow" do
      let(:item) { create(:item, name: "Flow Item", organization: organization) }
      let(:storage_location) { create(:storage_location, organization: organization) }

      before do
        create(:donation, :with_items, item: item, item_quantity: 7, storage_location: storage_location, organization: organization)
      end

      it "renders the flow table in its turbo frame" do
        get inventory_flow_storage_location_path(storage_location)

        expect(response).to be_successful
        frame = Nokogiri::HTML(response.body).at_css("turbo-frame#inventory_flow")
        row = frame.at_css("tbody tr[data-item-id='#{item.id}']")
        expect(row.css("td").map { |td| td.text.strip }).to eq(["Flow Item", "0", "7", "0", "0", "7", "7"])
        expect(frame.at_css("#inventory-flow-history-start")).to be_nil
      end

      it "notes when the date range starts before the inventory history" do
        travel_to(1.day.from_now) { SnapshotEvent.publish(organization) }

        get inventory_flow_storage_location_path(storage_location, filters: {date_range: "January 1, 2020 - January 31, 2020"})

        frame = Nokogiri::HTML(response.body).at_css("turbo-frame#inventory_flow")
        expect(frame.css("tbody tr")).to be_empty
        expect(frame.at_css("#inventory-flow-history-start").text).to include("Inventory history begins on")
      end

      it "does not show another organization's storage location" do
        other_location = create(:storage_location, organization: create(:organization))

        get inventory_flow_storage_location_path(other_location)

        expect(response).to have_http_status(:not_found)
      end

      def flow_cells(body)
        frame = Nokogiri::HTML(body).at_css("turbo-frame#inventory_flow")
        rows = frame.css("tbody tr").to_h do |tr|
          [tr["data-item-id"].to_i, tr.css("td").map { |td| td.text.strip }]
        end
        [rows, frame.css("tfoot td").map { |td| td.text.strip }]
      end

      context "with a date range" do
        let(:other_item) { create(:item, name: "Other Item", organization: organization) }

        before do
          travel_to(Time.zone.local(2026, 1, 15)) do
            create(:donation, :with_items, item: other_item, item_quantity: 20, storage_location: storage_location, organization: organization)
          end
          travel_to(Time.zone.local(2026, 2, 10)) do
            distribution = create(:distribution, :with_items, item: other_item, item_quantity: 12, storage_location: storage_location, organization: organization)
            DistributionEvent.publish(distribution)
          end
          travel_to(Time.zone.local(2026, 3, 5)) do
            create(:donation, :with_items, item: other_item, item_quantity: 100, storage_location: storage_location, organization: organization)
          end
        end

        it "counts records before the range in the start, records in it as flows, and leaves later records out" do
          get inventory_flow_storage_location_path(storage_location, filters: {date_range: "February 1, 2026 - February 28, 2026"})

          rows, totals = flow_cells(response.body)
          # The "Flow Item" donation from the outer before block is made today, after the range.
          expect(rows.keys).to eq([other_item.id])
          expect(rows[other_item.id]).to eq(["Other Item", "20", "0", "12", "0", "-12", "8"])
          expect(totals).to eq(["Total", "20", "0", "12", "0", "-12", "8"])
          change_cell = Nokogiri::HTML(response.body).css("tr[data-item-id='#{other_item.id}'] td")[5]
          expect(change_cell["class"]).to include("modal-body-warning-text")
        end
      end

      context "when the date range starts before the inventory snapshot and ends after it" do
        let(:snapshot_time) { 1.day.from_now.change(usec: 0) }

        before do
          travel_to(snapshot_time) { SnapshotEvent.publish(organization) }
          travel_to(snapshot_time + 1.day) do
            create(:donation, :with_items, item: item, item_quantity: 3, storage_location: storage_location, organization: organization)
          end
        end

        it "leaves the start quantity and change blank and counts flows from the snapshot" do
          date_range = "#{(snapshot_time - 1.year).to_date.to_fs(:long)} - #{(snapshot_time + 1.week).to_date.to_fs(:long)}"
          get inventory_flow_storage_location_path(storage_location, filters: {date_range: date_range})

          rows, totals = flow_cells(response.body)
          expect(rows[item.id]).to eq(["Flow Item", "", "3", "0", "0", "", "10"])
          expect(totals).to eq(["Total", "", "3", "0", "0", "", "10"])
          expect(Nokogiri::HTML(response.body).at_css("#inventory-flow-history-start").text)
            .to include("Inventory history begins on #{snapshot_time.to_date.to_fs(:long)}")
        end
      end

      it "formats quantities with thousands separators" do
        create(:donation, :with_items, item: item, item_quantity: 1500, storage_location: storage_location, organization: organization)

        get inventory_flow_storage_location_path(storage_location)

        rows, totals = flow_cells(response.body)
        expect(rows[item.id]).to eq(["Flow Item", "0", "1,507", "0", "0", "1,507", "1,507"])
        expect(totals).to eq(["Total", "0", "1,507", "0", "0", "1,507", "1,507"])
      end

      it "ignores a malformed filters param" do
        get inventory_flow_storage_location_path(storage_location, filters: "x")

        expect(response).to be_successful
        rows, _totals = flow_cells(response.body)
        expect(rows[item.id]).to eq(["Flow Item", "0", "7", "0", "0", "7", "7"])
      end

      it "falls back to the default date range when the range is invalid" do
        get inventory_flow_storage_location_path(storage_location, filters: {date_range: "not a date range"})

        expect(response).to be_successful
        rows, _totals = flow_cells(response.body)
        expect(rows[item.id]).to eq(["Flow Item", "0", "7", "0", "0", "7", "7"])
      end
    end

    describe "GET #destroy" do
      it "redirects to #index" do
        delete storage_location_path(id: create(:storage_location, organization: organization))
        expect(response).to redirect_to(storage_locations_path)
      end
    end

    describe "PUT #deactivate" do
      context "with inventory" do
        let(:storage_location) { create(:storage_location, :with_items, organization: organization) }

        it "does not discard" do
          put storage_location_deactivate_path(storage_location_id: storage_location.id, format: :json)
          expect(storage_location.reload.discarded?).to eq(false)
        end
      end

      let(:storage_location) { create(:storage_location, organization: organization) }

      it "discards" do
        put storage_location_deactivate_path(storage_location_id: storage_location.id, format: :json)
        expect(storage_location.reload.discarded?).to eq(true)
      end
    end

    describe "PUT #reactivate" do
      let(:storage_location) { create(:storage_location, organization: organization, discarded_at: Time.zone.now) }

      it "undiscards" do
        put storage_location_reactivate_path(storage_location_id: storage_location.id, format: :json)
        expect(storage_location.reload.discarded?).to eq(false)
      end
    end

    describe "GET #inventory" do
      def item_to_h(view_item)
        {
          'item_id' => view_item.item_id,
          'item_name' => view_item.name,
          'quantity' => view_item.quantity
        }
      end

      let(:storage_location) { create(:storage_location, :with_items, organization: organization) }
      let(:items_at_storage_location) do
        View::Inventory.new(organization.id).items_for_location(storage_location.id).map(&method(:item_to_h))
      end
      let(:inactive_items) do
        View::Inventory.new(organization.id).items_for_location(storage_location.id)
          .select { |i| !i.active }
          .map(&method(:item_to_h))
      end

      context "without any overrides" do
        it "returns a collection that only includes items at the storage location" do
          get inventory_storage_location_path(storage_location, format: :json)
          expect(response.parsed_body).to eq(items_at_storage_location)
        end

        it "returns items sorted alphabetically by item name" do
          get inventory_storage_location_path(storage_location, format: :json)
          sorted_items = items_at_storage_location.sort_by { |item| item['item_name'].downcase }
          expect(response.parsed_body).to eq(sorted_items)
        end
      end

      context "when also including inactive items" do
        let(:organization) { create(:organization, :with_items) }

        it "returns a collection that also includes items that have been deactivated" do
          organization.items.first.update(active: false)
          get inventory_storage_location_path(storage_location, format: :json, include_deactivated_items: true)
          organization.items.first.update(active: true)
          expect(response.parsed_body).to eq(items_at_storage_location + inactive_items)
        end
      end

      context "when also including omitted items" do
        it "returns a collection that also includes all items, but with zeroed quantities" do
          get inventory_storage_location_path(storage_location, format: :json, include_omitted_items: true)
          expect(response.parsed_body.count).to eq(organization.items.count)
        end

        it "contains a collection of ducktyped entries that respond the same" do
          get inventory_storage_location_path(storage_location, format: :json, include_omitted_items: true)
          collection = response.parsed_body
          expect(collection.first.keys).to match_array(%w[item_id item_name quantity])
          expect(collection.last.keys).to match_array(%w[item_id item_name quantity])
        end
      end
    end

    describe "POST #create" do
      let(:params) do
        {
          storage_location: {
            name: "New Storage Location",
            address: "123 New Street",
            square_footage: -100
          }
        }
      end

      it "shows an error when square footage is negative" do
        post storage_locations_path, params: params
        expect(response.body).to include("Square footage must be greater than or equal to 0")
      end
    end

    describe "PATCH #update" do
      let(:storage_location) { create(:storage_location, organization: organization) }
      let(:params) do
        {
          storage_location: {
            name: "Updated Name",
            address: "123 Updated Street",
            square_footage: -100
          }
        }
      end

      it "shows an error when square footage is negative" do
        patch storage_location_path(storage_location), params: params
        expect(response.body).to include("Square footage must be greater than or equal to 0")
      end
    end
  end

  context "While not signed in" do
    it "redirects GET #inventory_flow to sign in" do
      storage_location = create(:storage_location, organization: organization)

      get inventory_flow_storage_location_path(storage_location)

      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
