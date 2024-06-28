RSpec.describe "StorageLocations", type: :request do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:organization_admin) { create(:organization_admin, organization: organization) }

  context "While signed in" do
    before do
      sign_in(user)
    end

    describe "GET #index" do
      before { create(:storage_location, name: "Test Storage Location", address: "123 Donation Site Way", warehouse_type: StorageLocation::WAREHOUSE_TYPES.first) }

      context "html" do
        let(:response_format) { 'html' }

        it "succeeds" do
          get storage_locations_path(format: response_format)
          expect(response).to be_successful
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
      end

      context "csv" do
        let(:response_format) { 'csv' }
        it "succeeds" do
          get storage_locations_path(format: response_format)
          expect(response).to be_successful
        end

        it "includes headers followed by alphabetized item names" do
          storage_location_with_items = create(:storage_location)
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

          expect(response.body.split("\n")[0]).to eq([StorageLocation.csv_export_headers, item3.name, item2.name, item1.name].join(','))
        end

        context "when read_events feature toggle is enabled" do
          # Addresses used for storage locations must have associated geocoder stubs.
          # See calls to Geocoder::Lookup::Test.add_stub in spec/rails_helper.rb
          let(:storage_location_with_duplicate_item) { create(:storage_location, name: "Storage Location with Duplicate Items", address: "1500 Remount Road, Front Royal, VA 22630", warehouse_type: StorageLocation::WAREHOUSE_TYPES.first) }
          let(:storage_location_with_items) { create(:storage_location, name: "Storage Location with Items", address: "123 Donation Site Way", warehouse_type: StorageLocation::WAREHOUSE_TYPES.first) }
          let(:storage_location_with_unique_item) { create(:storage_location, name: "Storage Location with Unique Items", address: "Smithsonian Conservation Center new", warehouse_type: StorageLocation::WAREHOUSE_TYPES.first) }
          let(:item1) { create(:item, name: 'A') }
          let(:item2) { create(:item, name: 'B') }
          let(:item3) { create(:item, name: 'C') }
          let(:item4) { create(:item, name: 'D') }
          let!(:inactive_item) { create(:item, name: 'inactive item', active: false) }

          before do
            allow(Event).to receive(:read_events?).and_return(true)

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

          it "Generates csv with Storage Location fields, alphabetized item names, item quantities lined up in their columns, and zeroes for no inventory" do
            get storage_locations_path(format: response_format)
            # The first address below is quoted since it contains commas
            csv = <<~CSV
              Name,Address,Square Footage,Warehouse Type,Total Inventory,A,B,C,D
              Storage Location with Duplicate Items,"1500 Remount Road, Front Royal, VA 22630",100,Residential space used,1,0,0,1,0
              Storage Location with Items,123 Donation Site Way,100,Residential space used,3,1,1,1,0
              Storage Location with Unique Items,Smithsonian Conservation Center new,100,Residential space used,5,0,0,0,5
              Test Storage Location,123 Donation Site Way,100,Residential space used,0,0,0,0,0
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
          post import_inventory_storage_locations_path(organization_name: organization.to_param), params: params

          expect(response).to be_redirect
          expect(response).to have_error "Could not complete action: inventory already has items stored"
        end
      end
    end
    describe "GET #show" do
      let(:item) { create(:item, name: "Test Item") }
      let(:item2) { create(:item, name: "Test Item2") }
      let(:item3) { create(:item, name: "Test Item3", active: false) }

      let(:storage_location) { create(:storage_location, organization: organization) }
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

        it "should return a correct response" do
          get storage_location_path(storage_location, format: response_format)
          expect(response).to be_successful
          expect(response.body).to include("Smithsonian")
          expect(response.body).to include("Test Item")
          expect(response.body).to include("Test Item2")
          expect(response.body).not_to include("Test Item3")
          expect(response.body).to include("200")
        end

        context "with version date set", versioning: true do
          let(:inventory_item) { storage_location.inventory_items.first }

          context "with a version found" do
            context "with events_read on" do
              before(:each) { allow(Event).to receive(:read_events?).and_return(true) }
              context "before active events" do
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
                    expect(response.body).to include("Smithsonian")
                    expect(response.body).to include("Test Item")
                    expect(response.body).to include("100")
                  end
                end
              end

              context "with active events" do
                it 'should show the right version' do
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
                    expect(response.body).to include("Smithsonian")
                    expect(response.body).to include("Test Item")
                    expect(response.body).to include("100")
                  end
                end
              end
            end
            context "with events_read off" do
              before(:each) { allow(Event).to receive(:read_events?).and_return(false) }
              it "should show the version specified" do
                travel 1.day do
                  inventory_item.update!(quantity: 100)
                end
                travel 1.week do
                  inventory_item.update!(quantity: 300)
                end
                travel 2.weeks do
                  get storage_location_path(storage_location, format: response_format,
                    version_date: 9.days.ago.to_date.to_fs(:db))
                  expect(response).to be_successful
                  expect(response.body).to include("Smithsonian")
                  expect(response.body).to include("Test Item")
                  expect(response.body).to include("100")
                end
              end
            end
          end

          context "with no version found" do
            it "should show N/A" do
              get storage_location_path(storage_location, format: response_format,
                version_date: 1.week.ago.to_date.to_fs(:db))
              expect(response).to be_successful
              expect(response.body).to include("Smithsonian")
              expect(response.body).to include("Test Item")
              # event world doesn't care about versions
              expect(response.body).to include("N/A") unless Event.read_events?(organization)
            end
          end
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
      let(:inventory_items_at_storage_location) { storage_location.inventory_items.map(&:to_h) }
      let(:inactive_inventory_items) { organization.inventory_items.inactive.map(&:to_h) }
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
          expect(response.parsed_body).to eq(inventory_items_at_storage_location)
        end
      end

      context "when also including inactive items" do
        let(:organization) { create(:organization, :with_items) }

        it "returns a collection that also includes items that have been deactivated" do
          organization.items.first.update(active: false)
          get inventory_storage_location_path(storage_location, format: :json, include_deactivated_items: true)
          organization.items.first.update(active: true)
          expect(response.parsed_body).to eq(items_at_storage_location + inactive_items)
          expect(response.parsed_body).to eq(inventory_items_at_storage_location + inactive_inventory_items)
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

    context "Looking at a different organization" do
      let(:object) { create(:storage_location, organization: create(:organization)) }
      include_examples "requiring authorization"
    end
  end

  context "While not signed in" do
    let(:object) { create(:storage_location) }

    include_examples "requiring authorization"
  end
end
