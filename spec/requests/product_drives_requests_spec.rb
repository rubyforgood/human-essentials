RSpec.describe "ProductDrives", type: :request do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }

  context "while not signed in" do
    it "is unsuccessful" do
      get product_drives_path

      expect(response).not_to be_successful
    end
  end

  context "While signed in >" do
    before do
      sign_in(user)
    end

    describe "GET #index" do
      it "returns http success" do
        get product_drives_path

        expect(response).to be_successful
      end

      it 'displays only product drives that belong to organization and that match drive name and date range' do
        filter_params = {
          date_range: date_range_picker_params(Date.parse('20/01/2000'), Date.parse('22/01/2000')),
          by_name: "AAAA"
        }

        product_drive = create(:product_drive, organization: organization, name: "AAAA", start_date: '20/01/2000', end_date: '22/01/2000')

        product_drive_two = create(:product_drive, organization: organization, name: "BBBB", start_date: '20/01/2000', end_date: '22/01/2000')
        product_drive_three = create(:product_drive, organization: create(:organization), name: "AAAA", start_date: '20/01/2000', end_date: '22/01/2000')
        product_drive_four = create(:product_drive, organization: organization, name: "AAAA", start_date: '20/01/1990', end_date: '22/01/1990')
        product_drive_five = create(:product_drive, organization: organization, name: "AAAA", start_date: '20/01/2022', end_date: '22/01/2022')

        get product_drives_path(filters: filter_params)

        expect(response).to be_successful

        expect(response.body).to include(product_drive_path(product_drive.id))

        expect(response.body).not_to include(product_drive_path(product_drive_two.id))
        expect(response.body).not_to include(product_drive_path(product_drive_three.id))
        expect(response.body).not_to include(product_drive_path(product_drive_four.id))
        expect(response.body).not_to include(product_drive_path(product_drive_five.id))
      end

      it_behaves_like "allows filtering by tag", ProductDrive do
        let(:index_path) { product_drives_path(params) }
      end

      context "csv" do
        it 'is successful' do
          get product_drives_path(format: :csv)

          expect(response).to be_successful
          expect(response.header['Content-Type']).to include 'text/csv'

          expected_headers = Exports::ExportProductDrivesCSVService::HEADERS + organization.items.order(:name).pluck(:name)
          expect(response.body.chomp.split(",")).to eq(expected_headers)
        end

        it 'returns ONLY the associated product drives' do
          create(:product_drive, name: 'product_drive', organization: organization)
          create(:product_drive, name: 'unassociated_product_drive', organization: create(:organization))

          get product_drives_path(format: :csv)

          expect(response.body).to include('product_drive')
          expect(response.body).not_to include('unassociated_product_drive')
        end

        it 'returns ONLY the product drives within a selected date range (inclusive)' do
          create(
            :product_drive,
            name: 'early_product_drive',
            start_date: '30/01/1970',
            end_date: '30/01/1971',
            organization: organization
          )
          create(
            :product_drive,
            name: 'product_drive_within_date_range',
            start_date: '30/01/1980',
            end_date: '30/01/1981',
            organization: organization
          )
          create(
            :product_drive,
            name: 'product_drive_on_date_range',
            start_date: '30/01/1979',
            end_date: '30/01/1982',
            organization: organization
          )

          create(
            :product_drive,
            name: 'late_product_drive',
            start_date: '30/01/1990',
            end_date: '30/01/1991',
            organization: organization
          )

          get product_drives_path(format: :csv, filters: { date_range: date_range_picker_params(Date.parse('30/01/1979'), Date.parse('30/01/1982')) })

          expect(response.body).to include('product_drive_within_date_range')
          expect(response.body).to include('product_drive_on_date_range')
          expect(response.body).not_to include('early_product_drive')
          expect(response.body).not_to include('late_product_drive')
        end

        context "when organization has items" do
          let(:organization) { create(:organization, :with_items) }

          it "returns the quantity of all organization's items" do
            product_drive = create(:product_drive, name: 'product_drive', organization: organization)

            active_item, inactive_item = organization.items.first(2)
            inactive_item.update!(active: false)

            donation = create(:product_drive_donation, product_drive: product_drive)
            create(:line_item, :donation, itemizable_id: donation.id, item_id: active_item.id, quantity: 4)
            create(:line_item, :donation, itemizable_id: donation.id, item_id: inactive_item.id, quantity: 5)

            get product_drives_path(format: :csv)

            row = response.body.split("\n")[1]
            cells = row.split(',')
            expect(response.body).to include(active_item.name)
            expect(response.body).to include(inactive_item.name)
            expect(cells.count('4')).to eq(1)
            expect(cells.count('5')).to eq(1)
            expect(cells.count('0')).to eq(organization.items.count - 2)
          end

          it "only counts items within the selected date range" do
            item = organization.items.first
            product_drive = create(
              :product_drive,
              name: 'product_drive_within_date_range',
              start_date: '20/01/2023',
              end_date: '30/01/2023',
              organization: organization
            )

            donation = create(:product_drive_donation, product_drive: product_drive, issued_at: '21/01/2023')
            create(:line_item, :donation, itemizable_id: donation.id, item_id: item.id, quantity: 4)
            donation = create(:product_drive_donation, product_drive: product_drive, issued_at: '26/01/2023')
            create(:line_item, :donation, itemizable_id: donation.id, item_id: item.id, quantity: 10)

            get product_drives_path(format: :csv, filters: { date_range: date_range_picker_params(Date.parse('20/01/2023'), Date.parse('25/01/2023')) })

            row = response.body.split("\n")[1]
            cells = row.split(',')
            expect(cells.count('4')).to eq(2)
            expect(cells.count('0')).to eq(organization.items.count - 1)
          end
        end
      end

      describe "pagination" do
        around do |ex|
          old_default = Kaminari.config.default_per_page
          Kaminari.config.default_per_page = 2
          ex.run
          Kaminari.config.default_per_page = old_default
        end

        before do
          # Create a list of Product Drives to exceed pagination limit
          create_list(:product_drive, 10, organization: organization)

          # Fetch Product Drives before assertions
          get product_drives_path
        end

        it "displays pagination controls when there are more product drives than default per page" do
          expect(response).to be_successful

          parsed_html = Nokogiri::HTML(response.body)

          # Select the Product Drives table, which is the only table in the view
          # and count the rows
          product_drives_table = parsed_html.at_css("table.table")
          row_count = product_drives_table.css("tbody tr").size

          # There should be 2 rows on the first page--the default per page configured above
          expect(row_count).to eq(2)

          # Check that pagination controls (e.g., "Next" button) appear
          next_button = parsed_html.at_css('a, button') { |el| el.text.strip == 'Next' }
          expect(next_button).not_to be_nil
        end
      end
    end

    describe "GET #new" do
      it "returns http success" do
        get new_product_drive_path
        expect(response).to be_successful
      end
    end

    describe "POST#create" do
      let!(:tag) { create(:tag, name: "Foo", organization:) }
      let(:valid_params) { attributes_for(:product_drive).merge(tags: ["Foo", "Bar"]) }

      it "returns redirect http status" do
        post product_drives_path(product_drive: valid_params)
        expect(response).to have_http_status(:redirect)
      end

      it "creates drives with tags" do
        post product_drives_path(product_drive: valid_params)

        expect(ProductDrive.last.tags.map(&:name)).to include("Foo", "Bar")
      end

      context "with invalid params" do
        # start_date is required so this will fail validation
        let(:invalid_params) do
          valid_params.merge(start_date: "")
        end

        it "preserves tags entered" do
          post product_drives_path(product_drive: invalid_params)

          expect(flash[:error]).to eq("Something didn't work quite right -- try again?")
          expect(response.body).to include("Foo")
        end
      end
    end

    describe "PUT#update" do
      let!(:foo_tag) { create(:tag, name: "Foo", organization:) }
      let!(:bar_tag) { create(:tag, name: "Bar", organization:) }
      let(:product_drive) { create(:product_drive, organization: organization) }
      let(:valid_params) { product_drive.attributes.symbolize_keys.merge(tags: ["Foo", "Bar"]) }

      it "returns redirect http status" do
        put product_drive_path(id: product_drive.id, product_drive: valid_params)
        expect(response).to have_http_status(:redirect)
      end

      it "updates drive tags" do
        expect {
          put product_drive_path(id: product_drive.id, product_drive: valid_params)
        }.to change { product_drive.reload.tags.map(&:name).sort }.from([]).to(["Bar", "Foo"])
      end

      context "with invalid params" do
        # start_date is required so this will fail validation
        let(:invalid_params) do
          valid_params.merge(start_date: "")
        end

        it "preserves tags entered" do
          put product_drive_path(id: product_drive.id, product_drive: invalid_params)

          expect(flash[:error]).to eq("Something didn't work quite right -- try again?")
          expect(response.body).to include("Foo", "Bar")
        end
      end
    end

    describe "GET #edit" do
      it "returns http success" do
        product_drive = create(:product_drive, organization: organization)

        get edit_product_drive_path(id: product_drive.id)
        expect(response).to be_successful
      end
    end

    describe "GET #show" do
      it "returns http success" do
        product_drive = create(:product_drive, organization: organization)

        get product_drive_path(id: product_drive.id)
        expect(response).to be_successful
      end

      it "shows appropriate number on the UI" do
        product_drive = create(:product_drive, organization: organization)
        participant = create(:product_drive_participant)
        create(:donation, :with_items, item_quantity: 4862167, source: Donation::SOURCES[:product_drive], product_drive: product_drive, product_drive_participant: participant)

        get product_drive_path(id: product_drive.id)

        expect(response.body).to include("4862167")
      end
    end

    describe "DELETE #destroy" do
      let(:product_drive) { create(:product_drive, organization: organization) }

      it "redirects to the index" do
        delete product_drive_path(id: product_drive.id)
        expect(response).to redirect_to(product_drives_path)
      end

      context "when the product drive has associated donations" do
        it "does not delete and redirects with an error" do
          create(:donation, product_drive: product_drive)

          delete product_drive_path(id: product_drive.id)
          expect(response).to redirect_to(product_drive_path(product_drive))
          expect(flash[:error]).to eq("Cannot delete record because dependent donations exist")
        end
      end
    end
  end
end
