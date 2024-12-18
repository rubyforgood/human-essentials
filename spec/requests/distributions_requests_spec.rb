RSpec.describe "Distributions", type: :request do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:organization_admin) { create(:organization_admin, organization: organization) }

  let(:secret_key) { "HI MOM THIS IS ME AND I'M CODING" }
  let(:crypt) { ActiveSupport::MessageEncryptor.new(secret_key) }
  let(:hashed_id) { CGI.escape(crypt.encrypt_and_sign(organization.id)) }
  before(:each) do
    allow(Rails.application).to receive(:secret_key_base).and_return(secret_key)
  end

  context "While signed in" do
    before do
      sign_in(user)
    end

    describe "GET #itemized_breakdown" do
      let(:fake_csv) { "FAKE OUTPUT" }

      before do
        allow_any_instance_of(DistributionItemizedBreakdownService).to receive(:fetch_csv).and_return(fake_csv)
      end

      it "returns http success" do
        get itemized_breakdown_distributions_path(format: :csv)

        expect(response).to be_successful
        expect(response.body).to eq(fake_csv)
      end
    end

    describe "GET #print" do
      it "returns http success" do
        get print_distribution_path(id: create(:distribution).id)
        expect(response).to be_successful
      end

      context "with signature lines enabled" do
        it "returns http success" do
          organization.update!(signature_for_distribution_pdf: true)
          get print_distribution_path(id: create(:distribution).id)
          expect(response).to be_successful
        end
      end

      context "with non-UTF8 characters" do
        let(:non_utf8_partner) { create(:partner, name: "KOKA Keiki O Ka ‘Āina") }

        it "returns http success" do
          get print_distribution_path(id: create(:distribution, partner: non_utf8_partner).id)
          expect(response).to be_successful
        end
      end
    end

    describe "GET #reclaim" do
      it "returns http success" do
        get distributions_path(id: create(:distribution).id)
        expect(response).to be_successful
      end
    end

    describe "GET #index" do
      let(:item) { create(:item, value_in_cents: 100, organization: organization) }
      let!(:distribution) { create(:distribution, :with_items, :past, item: item, item_quantity: 10, organization: organization) }

      it "returns http success" do
        get distributions_path
        expect(response).to be_successful
      end

      it "sums distribution totals accurately" do
        create(:distribution, :with_items, item_quantity: 5, organization: organization)
        create(:line_item, :distribution, itemizable_id: distribution.id, quantity: 7)
        get distributions_path
        expect(assigns(:total_items_all_distributions)).to eq(22)
        expect(assigns(:total_items_paginated_distributions)).to eq(22)
      end

      it "shows an enabled edit and reclaim button" do
        get distributions_path
        page = Nokogiri::HTML(response.body)
        edit = page.at_css("a[href='#{edit_distribution_path(id: distribution.id)}']")
        reclaim = page.at_css("a.btn-danger[href='#{distribution_path(id: distribution.id)}']")
        expect(edit.attr("class")).not_to match(/disabled/)
        expect(reclaim.attr("class")).not_to match(/disabled/)
        expect(response.body).not_to match(/Has Inactive Items/)
      end

      context "with a disabled item" do
        before do
          item.update(active: false)
        end

        it "shows a disabled edit and reclaim button" do
          get distributions_path
          page = Nokogiri::HTML(response.body)
          edit = page.at_css("a[href='#{edit_distribution_path(id: distribution.id)}']")
          reclaim = page.at_css("a.btn-danger[href='#{distribution_path(id: distribution.id)}']")
          expect(edit.attr("class")).to match(/disabled/)
          expect(reclaim.attr("class")).to match(/disabled/)
          expect(response.body).to match(/Has Inactive Items/)
        end
      end

      context "with filters" do
        it "shows all active partners in dropdown filter unrestricted by current filter" do
          inactive_partner_name = create(:partner, :deactivated, organization:).name
          active_partner_name = distribution.partner.name

          # Filter by date with no distributions
          params = { filters: { date_range: "January 1,9999 - January 1,9999"} }

          get distributions_path, params: params
          page = Nokogiri::HTML(response.body)
          partner_select = page.at_css("select[name='filters[by_partner]']")

          expect(partner_select).to be_present
          expect(partner_select.text).to include(active_partner_name)
          expect(partner_select.text).not_to include(inactive_partner_name)
        end
      end

      context "when filtering by item id" do
        let!(:item_2) { create(:item, value_in_cents: 100, organization: organization) }
        let(:params) { { filters: { by_item_id: item.id } } }

        before do
          distribution.line_items << create(:line_item, item: item_2, quantity: 10)
        end

        it "shows value and quantity for that item in distributions" do
          get distributions_path, params: params

          page = Nokogiri::HTML(response.body)
          item_quantity, item_value = page.css("table tbody tr td.numeric")

          # total value/quantity of distribution
          expect(distribution.total_quantity).to eq(20)
          expect(distribution.value_per_itemizable).to eq(2000)

          # displays quantity of filtered item in distribution
          # displays total value of distribution
          expect(item_quantity.text).to eq("10")
          expect(item_value.text).to eq("$20.00")
        end

        it "changes the total quantity header" do
          get distributions_path, params: params

          page = Nokogiri::HTML(response.body)
          item_total_header, item_value_header = page.css("table thead tr th.numeric")

          expect(item_total_header.text).to eq("Total #{item.name}")
          expect(item_value_header.text).to eq("Total Value")
        end
      end

      context "when filtering by item category id" do
        let!(:item_category) { create(:item_category, organization:) }
        let!(:item_category_2) { create(:item_category, organization:) }
        let!(:item_2) { create(:item, item_category: item_category_2, value_in_cents: 100, organization: organization) }
        let(:params) { { filters: { by_item_category_id: item.item_category_id } } }

        before do
          item.update(item_category: item_category)
          distribution.line_items << create(:line_item, item: item_2, quantity: 10)
        end

        it "shows value and quantity for that item category in distributions" do
          get distributions_path, params: params

          page = Nokogiri::HTML(response.body)
          item_quantity, item_value = page.css("table tbody tr td.numeric")

          # total value/quantity of distribution
          expect(distribution.total_quantity).to eq(20)
          expect(distribution.value_per_itemizable).to eq(2000)

          # displays quantity of filtered item in distribution
          # displays total value of distribution
          expect(item_quantity.text).to eq("10")
          expect(item_value.text).to eq("$20.00")
        end

        it "changes the total quantity header" do
          get distributions_path, params: params

          page = Nokogiri::HTML(response.body)
          item_total_header, item_value_header = page.css("table thead tr th.numeric")

          expect(item_total_header.text).to eq("Total in #{item_category.name}")
          expect(item_value_header.text).to eq("Total Value")
        end

        it "doesn't show duplicate distributions" do
          # Add another item in given category so that a JOIN clauses would produce duplicates
          item.update(item_category: item_category_2, value_in_cents: 50)

          get distributions_path, params: params

          page = Nokogiri::HTML(response.body)
          distribution_rows = page.css("table tbody tr")

          expect(distribution_rows.count).to eq(1)
        end
      end
    end

    describe "POST #create" do
      let!(:storage_location) { create(:storage_location, organization: organization) }
      let!(:partner) { create(:partner, organization: organization) }
      let(:issued_at) { Time.current }
      let(:distribution) do
        { storage_location_id: storage_location.id, partner_id: partner.id, issued_at:, delivery_method: :delivery }
      end

      it "redirects to #show on success" do
        expect(storage_location).to be_valid
        expect(partner).to be_valid

        expect(PartnerMailerJob).to receive(:perform_later).once
        post distributions_path(distribution:, format: :turbo_stream)

        expect(response).to have_http_status(:redirect)
        last_distribution = Distribution.last
        expect(response).to redirect_to(distribution_path(last_distribution))
      end

      it "renders #new again on failure, with notice" do
        post distributions_path(distribution: { comment: nil, partner_id: nil, storage_location_id: nil }, format: :turbo_stream)
        expect(response).to have_http_status(400)
        expect(response).to have_error
      end

      it "renders #new on failure with only active items in dropdown" do
        create(:item, organization: organization, name: 'Active Item')
        create(:item, :inactive, organization: organization, name: 'Inactive Item')

        post distributions_path(distribution: { comment: nil, partner_id: nil, storage_location_id: nil }, format: :turbo_stream)
        expect(response).to have_http_status(400)

        page = Nokogiri::HTML(response.body)
        selectable_items = page.at_css("select.line_item_name").text.split("\n")

        expect(selectable_items).to include("Active Item")
        expect(selectable_items).not_to include("Inactive Item")
      end

      context "Deactivated partners should not be displayed in partner dropdown" do
        before do
          create(:partner, name: 'Active Partner', organization: organization, status: "approved")
          create(:partner, name: 'Deactivated Partner', organization: organization, status: "deactivated")
        end

        it "should not display deactivated partners after error and re-render of form" do
          post distributions_path(distribution: { comment: nil, partner_id: nil, storage_location_id: nil }, format: :turbo_stream)
          expect(response).to have_http_status(400)
          expect(response).to have_error
          expect(response.body).not_to include("Deactivated Partner")
          expect(response.body).to include("Active Partner")
        end
      end

      context "with missing issued_at field" do
        let(:issued_at) { "" }

        it "fails and returns validation error message" do
          post distributions_path(distribution:, format: :turbo_stream)

          expect(response).to have_http_status(400)
          expect(flash[:error]).to include("Distribution date and time can't be blank")
        end
      end
    end

    describe "GET #new" do
      let!(:partner) { create(:partner, organization: organization) }
      let(:request) { create(:request, partner: partner, organization: organization, item_requests: item_requests) }
      let(:items) {
        [
          create(:item, :with_unit, organization: organization, name: 'Item 1', unit: 'pack'),
          create(:item, organization: organization, name: 'Item 2')
        ]
      }
      let(:item_requests) {
        [
          create(:item_request, item: items[0], quantity: 50, request_unit: 'pack'),
          create(:item_request, item: items[1], quantity: 25)
        ]
      }
      let(:storage_location) { create(:storage_location, :with_items, organization: organization) }
      let(:default_params) { { request_id: request.id } }

      it "returns http success" do
        get new_distribution_path(default_params)
        expect(response).to be_successful
        # default should be nothing selected
        page = Nokogiri::HTML(response.body)
        expect(page.css('#distribution_storage_location_id option[selected]')).to be_empty
      end

      it "should only show active items in item dropdown" do
        create(:item, :inactive, organization: organization, name: 'Inactive Item')

        get new_distribution_path(default_params)

        page = Nokogiri::HTML(response.body)
        selectable_items = page.at_css("select#barcode_item_barcodeable_id").text.split("\n")

        expect(selectable_items).to include("Item 1", "Item 2")
        expect(selectable_items).not_to include("Inactive Item")
      end

      context "with org default but no partner default" do
        it "selects org default" do
          organization.update!(default_storage_location: storage_location.id)
          get new_distribution_path(default_params)
          expect(response).to be_successful
          page = Nokogiri::HTML(response.body)
          expect(page.css(%(#distribution_storage_location_id option[selected][value="#{storage_location.id}"]))).not_to be_empty
        end
      end

      context "with partner default" do
        it "selects partner default" do
          location2 = create(:storage_location, :with_items)
          organization.update!(default_storage_location: location2.id)
          partner.update!(default_storage_location_id: storage_location.id)
          get new_distribution_path(default_params)
          expect(response).to be_successful
          page = Nokogiri::HTML(response.body)
          expect(page.css(%(#distribution_storage_location_id option[selected][value="#{storage_location.id}"]))).not_to be_empty
        end
      end

      context "Deactivated partners should not be displayed in partner dropdown" do
        before do
          create(:partner, name: 'Active Partner', organization: organization, status: "approved")
          create(:partner, name: 'Deactivated Partner', organization: organization, status: "deactivated")
        end

        it "should not display deactivated partners on new distribution" do
          get new_distribution_path(default_params)
          expect(response.body).not_to include("Deactivated Partner")
          expect(response.body).to include("Active Partner")
        end
      end

      context 'with units' do
        before(:each) do
          Flipper.enable(:enable_packs)
        end

        it 'should behave correctly' do
          get new_distribution_path(default_params)
          expect(response).to be_successful
          page = Nokogiri::HTML(response.body)

          # should have a disabled select and a hidden input
          expect(page.css('select[disabled][name="distribution[line_items_attributes][0][item_id]"]')).not_to be_empty
          expect(page.css('input[name="distribution[line_items_attributes][0][item_id]"]')).not_to be_empty
          expect(page.css('select[disabled][name="distribution[line_items_attributes][1][item_id]"]')).not_to be_empty
          expect(page.css('input[name="distribution[line_items_attributes][1][item_id]"]')).not_to be_empty

          # input with packs should be blank
          expect(page.css('#distribution_line_items_attributes_0_quantity').attr('value')).to eq(nil)

          # input with no packs should show quantity
          expect(page.css('#distribution_line_items_attributes_1_quantity').attr('value').value).to eq('25')
        end

        context 'with no request' do
          it 'should have no inputs' do
            get new_distribution_path({})
            expect(response).to be_successful
            page = Nokogiri::HTML(response.body)

            # blank input shown
            expect(page.css('select[name="distribution[line_items_attributes][0][item_id]"]')).not_to be_empty
            expect(page.css('#distribution_line_items_attributes_0_quantity').attr('value')).to eq(nil)
            # in the template
            expect(page.css('select[name="distribution[line_items_attributes][1][item_id]"]')).not_to be_empty
          end
        end
      end
    end

    describe "GET #show" do
      let(:item) { create(:item, organization: organization) }
      let!(:distribution) { create(:distribution, :with_items, item: item, item_quantity: 1, organization: organization) }

      it "sums distribution totals accurately" do
        distribution = create(:distribution, :with_items, item_quantity: 1, organization: organization)

        item_quantity = 6
        package_size = 2

        item = create(:item, package_size: package_size)
        create(
          :line_item,
          :distribution,
          itemizable_id: distribution.id,
          item_id: item.id,
          quantity: item_quantity
        )
        get distribution_path(id: distribution.id)

        expect(response).to be_successful
        expect(assigns(:total_quantity)).to eq(item_quantity + 1)
        expect(assigns(:total_package_count)).to eq(item_quantity / package_size)
      end

      it "shows an enabled edit button" do
        get distribution_path(id: distribution.id)
        page = Nokogiri::HTML(response.body)
        edit = page.at_css("a[href='#{edit_distribution_path(id: distribution.id)}']")
        expect(edit.attr("class")).not_to match(/disabled/)
        expect(response.body).not_to match(/please make the following items active:/)
      end

      context "with an inactive item" do
        before do
          item.update(active: false)
        end

        it "shows a disabled edit button" do
          get distribution_path(id: distribution.id)
          page = Nokogiri::HTML(response.body)
          edit = page.at_css("a[href='#{edit_distribution_path(id: distribution.id)}']")
          expect(edit.attr("class")).to match(/disabled/)
          expect(response.body).to match(/please make the following items active: #{item.name}/)
        end
      end
    end

    describe "GET #schedule" do
      it "returns http success" do
        get schedule_distributions_path
        expect(response).to be_successful
        page = Nokogiri::HTML(response.body)
        url = page.at_css('#copy-calendar-button').attributes['data-url'].value
        hash = url.match(/\?hash=(.*)/)[1]
        expect(crypt.decrypt_and_verify(CGI.unescape(hash))).to eq(organization.id)
      end
    end

    describe 'PATCH #picked_up' do
      subject { patch picked_up_distribution_path(id: distribution.id) }

      context 'when the distribution is successfully updated' do
        let(:distribution) { create(:distribution, state: :scheduled, organization: organization) }

        it "updates the state to 'complete'" do
          subject
          expect(distribution.reload.state).to eq 'complete'
        end

        it 'redirects the user back to the distributions page' do
          expect(subject).to redirect_to distribution_path
        end
      end
    end

    describe "GET #pickup_day" do
      it "returns http success" do
        get pickup_day_distributions_path
        expect(response).to be_successful
      end

      it "correctly sums the item counts from distributions" do
        first_item = create(:item, organization: organization)
        second_item = create(:item, organization: organization)
        first_distribution = create(:distribution, organization: organization)
        second_distribution = create(:distribution, organization: organization)
        create(:line_item, :distribution, item_id: first_item.id, itemizable_id: first_distribution.id, quantity: 7)
        create(:line_item, :distribution, item_id: first_item.id, itemizable_id: second_distribution.id, quantity: 4)
        create(:line_item, :distribution, item_id: second_item.id, itemizable_id: second_distribution.id, quantity: 5)
        get pickup_day_distributions_path
        expect(assigns(:daily_items).detect { |item| item[:name] == first_item.name }[:quantity]).to eq(11)
        expect(assigns(:daily_items).detect { |item| item[:name] == second_item.name }[:quantity]).to eq(5)
        expect(assigns(:daily_items).sum { |item| item[:quantity] }).to eq(16)
      end

      it "correctly sums the item package counts from distributions" do
        first_item = create(:item, package_size: 2, organization: organization)
        second_item = create(:item, package_size: 3, organization: organization)
        first_distribution = create(:distribution, organization: organization)
        second_distribution = create(:distribution, organization: organization)

        create(:line_item, :distribution, item_id: first_item.id, itemizable_id: first_distribution.id, quantity: 7)
        create(:line_item, :distribution, item_id: first_item.id, itemizable_id: second_distribution.id, quantity: 4)
        create(:line_item, :distribution, item_id: second_item.id, itemizable_id: second_distribution.id, quantity: 6)
        get pickup_day_distributions_path
        expect(assigns(:daily_items).detect { |item| item[:name] == first_item.name }[:package_count]).to eq(5)
        expect(assigns(:daily_items).detect { |item| item[:name] == second_item.name }[:package_count]).to eq(2)
        expect(assigns(:daily_items).sum { |item| item[:package_count] }).to eq(7)
      end
    end

    context "Looking at a different organization" do
      let(:object) { create(:distribution, organization: create(:organization)) }
      include_examples "requiring authorization"
    end

    describe "POST #update" do
      let(:location) { create(:storage_location, organization: organization) }
      let(:partner) { create(:partner, organization: organization) }

      let(:distribution) { create(:distribution, partner: partner, organization: organization) }
      let(:issued_at) { distribution.issued_at }
      let(:distribution_params) do
        { id: distribution.id,
          distribution: {
            partner_id: partner.id,
            storage_location_id: location.id,
            'issued_at(1i)' => issued_at.to_date.year,
            'issued_at(2i)' => issued_at.to_date.month,
            'issued_at(3i)' => issued_at.to_date.day
          }}
      end

      it "returns a 200" do
        patch distribution_path(distribution_params)
        expect(response.status).to redirect_to(distribution_path(distribution.to_param))
      end

      context "with invalid issued_at field" do
        let(:distribution_params) do
          { id: distribution.id,
            distribution: {
              partner_id: partner.id,
              storage_location_id: location.id,
              'issued_at(1i)' => issued_at.to_date.year,
              'issued_at(2i)' => issued_at.to_date.month,
              'issued_at(3i)' => nil # day part of date missing
            }}
        end

        it "fails and returns validation error message" do
          patch distribution_path(distribution_params)

          expect(flash[:error]).to include("Distribution date and time can't be blank")
          expect(response).not_to redirect_to(anything)
        end
      end

      describe "when changing storage location" do
        let(:item) { create(:item, organization: organization) }
        it "updates storage quantity correctly" do
          new_storage_location = create(:storage_location, organization: organization)
          create(:donation, :with_items, item: item, item_quantity: 30, storage_location: new_storage_location, organization: organization)
          distribution = create(:distribution, :with_items, item: item, item_quantity: 10, organization: organization)
          original_storage_location = distribution.storage_location
          line_item = distribution.line_items.first
          line_item_params = {
            "0" => {
              "_destroy" => "false",
              item_id: line_item.item_id,
              quantity: "5",
              id: line_item.id
            }
          }
          distribution_params = { storage_location_id: new_storage_location.id, line_items_attributes: line_item_params }
          expect do
            put distribution_path(id: distribution.id, distribution: distribution_params)
          end.to change { original_storage_location.size }.by(10) # removes the whole distribution of 10 - increasing inventory
          expect(new_storage_location.size).to eq 25
        end
      end

      context "mail follow up" do
        subject { patch distribution_path(distribution_params) }

        it "does not send an e-mail" do
          expect { subject }.not_to change { ActionMailer::Base.deliveries.count }
        end

        context "sending" do
          let(:issued_at) { distribution.issued_at + 1.day }

          it "does send an e-mail" do
            expect { subject }.to change { ActionMailer::Base.deliveries.count }.by(1)
          end
        end

        context "partner reminder sending switched off" do
          let(:issued_at) { distribution.issued_at + 1.day }
          before { partner.update!(send_reminders: false) }

          it "does not send the e-mail" do
            expect { subject }.not_to change { ActionMailer::Base.deliveries.count }
          end
        end
      end
    end

    describe "GET #edit" do
      let(:location) { create(:storage_location, organization: organization) }
      let(:partner) { create(:partner, organization: organization) }

      let(:distribution) { create(:distribution, partner: partner) }

      it "should show the distribution" do
        get edit_distribution_path(id: distribution.id)
        expect(response).to be_successful
        expect(response.body).not_to include("You’ve had an audit since this distribution was started.")
      end

      it "should show a warning if there is an inteverning audit" do
        distribution.update!(created_at: 1.week.ago)
        create(:audit, storage_location: distribution.storage_location, organization: organization)
        get edit_distribution_path(id: distribution.id)
        expect(response.body).to include("You’ve had an audit since this distribution was started.")
      end

      it "should not show a warning if the audit is for another location" do
        distribution.update!(created_at: 1.week.ago)
        create(:audit, storage_location: create(:storage_location))
        get edit_distribution_path(id: distribution.id)
        expect(response.body).not_to include("You’ve had an audit since this distribution was started.")
      end

      it "should display deactivated partners in partner dropdown" do
        create(:partner, name: 'Active Partner', organization: organization, status: "approved")
        create(:partner, name: 'Deactivated Partner', organization: organization, status: "deactivated")
        get edit_distribution_path(id: distribution.id)
        expect(response.body).to include("Deactivated Partner")
        expect(response.body).to include("Active Partner")
      end

      it "should only show active items in item dropdown" do
        create(:item, organization: organization, name: 'Active Item')
        create(:item, :inactive, organization: organization, name: 'Inactive Item')

        get edit_distribution_path(id: distribution.id)

        page = Nokogiri::HTML(response.body)
        selectable_items = page.at_css("select#barcode_item_barcodeable_id").text.split("\n")

        expect(selectable_items).to include("Active Item")
        expect(selectable_items).not_to include("Inactive Item")
      end

      context 'with units' do
        let!(:request) {
          create(:request,
            partner: partner,
            organization: organization,
            distribution_id: distribution.id,
            item_requests: item_requests)
        }
        let(:items) {
          [
            create(:item, :with_unit, organization: organization, name: 'Item 1', unit: 'pack'),
            create(:item, organization: organization, name: 'Item 2'),
            create(:item, organization: organization, name: 'Item 3')
          ]
        }
        let!(:item_requests) {
          [
            create(:item_request, item: items[0], quantity: 50, request_unit: 'pack'),
            create(:item_request, item: items[1], quantity: 25)
          ]
        }
        before(:each) do
          Flipper.enable(:enable_packs)
          create(:line_item, itemizable: distribution, item_id: items[0].id, quantity: 25)
          create(:line_item, itemizable: distribution, item_id: items[2].id, quantity: 10)
        end

        it 'should behave correctly' do
          get edit_distribution_path(id: distribution.id)
          expect(response).to be_successful
          page = Nokogiri::HTML(response.body)

          # should have a regular select and no hidden input
          expect(page.css('select[disabled][name="distribution[line_items_attributes][0][item_id]"]')).not_to be_empty
          expect(page.css('input[name="distribution[line_items_attributes][0][item_id]"]')).not_to be_empty

          # should have a regular select and no hidden input
          expect(page.css('select[name="distribution[line_items_attributes][1][item_id]"]')).not_to be_empty
          expect(page.css('select[disabled][name="distribution[line_items_attributes][1][item_id]"]')).to be_empty
          expect(page.css('input[name="distribution[line_items_attributes][1][item_id]"]')).to be_empty

          # should have a disabled select and a hidden input
          expect(page.css('select[disabled][name="distribution[line_items_attributes][2][item_id]"]')).not_to be_empty
          expect(page.css('input[name="distribution[line_items_attributes][2][item_id]"]')).not_to be_empty

          # existing inputs should show numbers
          expect(page.css('#distribution_line_items_attributes_0_quantity').attr('value').value).to eq('25')
          expect(page.css('#distribution_line_items_attributes_1_quantity').attr('value').value).to eq('10')

          # input from request should show 0
          expect(page.css('#distribution_line_items_attributes_2_quantity').attr('value').value).to eq('0')
        end

        context 'with no request' do
          it 'should have everything enabled' do
            request.destroy
            get edit_distribution_path(id: distribution.id)
            expect(response).to be_successful
            page = Nokogiri::HTML(response.body)

            expect(page.css('select[name="distribution[line_items_attributes][0][item_id]"]')).not_to be_empty
            expect(page.css('select[disabled][name="distribution[line_items_attributes][0][item_id]"]')).to be_empty
            expect(page.css('input[name="distribution[line_items_attributes][0][item_id]"]')).to be_empty
            expect(page.css('select[name="distribution[line_items_attributes][1][item_id]"]')).not_to be_empty
            expect(page.css('select[disabled][name="distribution[line_items_attributes][1][item_id]"]')).to be_empty
            expect(page.css('input[name="distribution[line_items_attributes][1][item_id]"]')).to be_empty
          end
        end
      end

      # Bug fix #4537
      context "when distribution sets storage location total inventory to zero" do
        let(:item1) { create(:item, name: "Item 1", organization: organization) }
        let(:test_storage_name) { "Test Storage" }
        let(:storage_location) { create(:storage_location, name: test_storage_name, organization: organization) }
        before(:each) do
          quantity = 20
          TestInventory.create_inventory(organization, {
            storage_location.id => {
              item1.id => quantity
            }
          })
          @distribution_all = create(:distribution, :with_items, item: item1, item_quantity: quantity, storage_location: storage_location, organization: organization)
          DistributionCreateService.new(@distribution_all).call
        end
        it "allows you to select the original storage location for the distribution" do
          get edit_distribution_path(id: @distribution_all.id)
          expect(response.body).to include("<option selected=\"selected\" value=\"#{storage_location.id}\">#{test_storage_name}</option>")
        end
      end
    end
  end

  context "While not signed in" do
    let(:object) { create(:distribution) }

    include_examples "requiring authorization"

    # calendar does not need signin
    describe 'GET #calendar' do
      before(:each) do
        allow(CalendarService).to receive(:calendar).and_return("SOME ICS STRING")
      end

      context 'with a correct hash id' do
        it 'should render the calendar' do
          get calendar_distributions_path(hash: hashed_id)
          expect(CalendarService).to have_received(:calendar).with(organization.id)
          expect(response.media_type).to include('text/calendar')
          expect(response.body).to eq('SOME ICS STRING')
        end
      end

      context 'without a correct hash id' do
        it 'should error unauthorized' do
          get calendar_distributions_path(hash: 'some-wrong-id')
          expect(response.status).to eq(401)
        end
      end
    end
  end
end
