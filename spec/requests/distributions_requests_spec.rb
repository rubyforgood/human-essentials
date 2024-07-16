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
      let(:item) { create(:item, organization: organization) }
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
    end

    describe "POST #create" do
      let!(:storage_location) { create(:storage_location, organization: organization) }
      let!(:partner) { create(:partner, organization: organization) }
      let(:distribution) do
        { storage_location_id: storage_location.id, partner_id: partner.id, delivery_method: :delivery }
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
    end

    describe "GET #new" do
      let!(:partner) { create(:partner, organization: organization) }
      let(:request) { create(:request, partner: partner, organization: organization) }
      let(:storage_location) { create(:storage_location, :with_items, organization: organization) }
      let(:default_params) { { request_id: request.id } }

      it "returns http success" do
        get new_distribution_path(default_params)
        expect(response).to be_successful
        # default should be nothing selected
        page = Nokogiri::HTML(response.body)
        expect(page.css('#distribution_storage_location_id option[selected]')).to be_empty
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

        # TODO this test is invalid in event-world since it's handled by the aggregate
        it "rollsback updates if quantity would go below 0" do
          next if Event.read_events?(organization)

          distribution = create(:distribution, :with_items, item_quantity: 10, organization: organization)
          original_storage_location = distribution.storage_location

          # adjust inventory so that updating will set quantity below 0
          inventory_item = original_storage_location.inventory_items.last
          inventory_item.quantity = 5
          inventory_item.save!

          new_storage_location = create(:storage_location)
          line_item = distribution.line_items.first
          line_item_params = {
            "0" => {
              "_destroy" => "false",
              item_id: line_item.item_id,
              quantity: "20",
              id: line_item.id
            }
          }
          distribution_params = { storage_location_id: new_storage_location.id, line_items_attributes: line_item_params }
          expect do
            put :update, params: { id: donation.id, distribution: distribution_params }
          end.to raise_error(NameError)
          expect(original_storage_location.size).to eq 5
          expect(new_storage_location.size).to eq 0
          expect(distribution.reload.line_items.first.quantity).to eq 10
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
