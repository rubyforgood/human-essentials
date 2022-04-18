RSpec.describe "StorageLocations", type: :request do
  let(:default_params) do
    { organization_id: @organization.to_param }
  end

  context "While signed in" do
    before do
      sign_in(@user)
    end

    describe "GET #index" do
      subject do
        get storage_locations_path(default_params.merge(format: response_format))
        response
      end

      before { create(:storage_location) }

      context "html" do
        let(:response_format) { 'html' }

        it { is_expected.to be_successful }
      end

      context "csv" do
        let(:response_format) { 'csv' }

        it { is_expected.to be_successful }
      end
    end

    describe "GET #new" do
      it "returns http success" do
        get new_storage_location_path(default_params)
        expect(response).to be_successful
      end
    end

    describe "GET #edit" do
      it "returns http success" do
        get edit_storage_location_path(default_params.merge(id: create(:storage_location, organization: @organization)))
        expect(response).to be_successful
      end
    end

    describe "POST #import_csv" do
      let(:model_class) { StorageLocation }

      context "with a csv file" do
        let(:file) { fixture_file_upload("#{model_class.name.underscore.pluralize}.csv", "text/csv") }
        subject { post import_csv_storage_locations_path(default_params), params: { file: file } }

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
        subject { post import_csv_storage_locations_path(default_params) }

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
        subject { post import_csv_storage_locations_path(default_params), params: { file: file } }

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

    describe "GET #show" do
      let(:item) { create(:item, name: "Test Item") }
      let(:storage_location) { create(:storage_location, organization: @organization) }
      let!(:inventory_item) { create(:inventory_item, storage_location: storage_location, item: item, quantity: 200) }

      context "html" do
        let(:response_format) { 'html' }

        it "should return a correct response" do
          get storage_location_path(storage_location, default_params.merge(format: response_format))
          expect(response).to be_successful
          expect(response.body).to include("Smithsonian")
          expect(response.body).to include("Test Item")
          expect(response.body).to include("200")
        end

        context "with version date set" do
          context "with a version found" do
            it "should show the version specified" do
              travel 1.day do
                inventory_item.update!(quantity: 100)
              end
              travel 1.week do
                inventory_item.update!(quantity: 300)
              end
              travel 2.weeks do
                get storage_location_path(storage_location, default_params.merge(format: response_format,
                  version_date: 9.days.ago.to_date.to_fs(:db)))
                expect(response).to be_successful
                expect(response.body).to include("Smithsonian")
                expect(response.body).to include("Test Item")
                expect(response.body).to include("100")
              end
            end
          end

          context "with no version found" do
            it "should show N/A" do
              get storage_location_path(storage_location, default_params.merge(format: response_format,
                version_date: 1.week.ago.to_date.to_fs(:db)))
              expect(response).to be_successful
              expect(response.body).to include("Smithsonian")
              expect(response.body).to include("Test Item")
              expect(response.body).to include("N/A")
            end
          end
        end
      end

      context "csv" do
        let(:response_format) { 'csv' }

        it "should be successful" do
          get storage_location_path(storage_location, default_params.merge(format: response_format))
          expect(response).to be_successful
        end
      end
    end

    describe "GET #destroy" do
      it "redirects to #index" do
        delete storage_location_path(default_params.merge(id: create(:storage_location, organization: @organization)))
        expect(response).to redirect_to(storage_locations_path)
      end
    end

    describe "GET #inventory" do
      let(:storage_location) { create(:storage_location, :with_items, organization: @organization) }
      let(:items_at_storage_location) { storage_location.inventory_items.map(&:to_h) }
      let(:inactive_items) { @organization.inventory_items.inactive.map(&:to_h) }

      context "without any overrides" do
        it "returns a collection that only includes items at the storage location" do
          get inventory_storage_location_path(storage_location, default_params.merge(format: :json))
          expect(response.parsed_body).to eq(items_at_storage_location)
        end
      end

      context "when also including inactive items" do
        it "returns a collection that also includes items that have been deactivated" do
          @organization.items.first.update(active: false)
          get inventory_storage_location_path(storage_location, default_params.merge(format: :json, include_deactivated_items: true))
          @organization.items.first.update(active: true)
          expect(response.parsed_body).to eq(items_at_storage_location + inactive_items)
        end
      end

      context "when also including omitted items" do
        it "returns a collection that also includes all items, but with zeroed quantities" do
          get inventory_storage_location_path(storage_location, default_params.merge(format: :json, include_omitted_items: true))
          expect(response.parsed_body.count).to eq(@organization.items.count)
        end

        it "contains a collection of ducktyped entries that respond the same" do
          get inventory_storage_location_path(storage_location, default_params.merge(format: :json, include_omitted_items: true))
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
