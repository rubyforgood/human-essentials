RSpec.describe DistributionsController, type: :controller do
  let(:default_params) do
    { organization_id: @organization.to_param }
  end

  context "While signed in" do
    before do
      sign_in(@user)
    end

    describe "GET #print" do
      subject { get :print, params: default_params.merge(id: create(:distribution).id) }
      it "returns http success" do
        expect(subject).to be_successful
      end

      context "with non-UTF8 characters" do
        let(:non_utf8_partner) { create(:partner, name: "KOKA Keiki O Ka ‘Āina") }
        subject { get :print, params: default_params.merge(id: create(:distribution, partner: non_utf8_partner).id) }

        it "returns http success" do
          expect(subject).to be_successful
        end
      end
    end

    describe "GET #reclaim" do
      subject { get :index, params: default_params.merge(organization_id: @organization, id: create(:distribution).id) }
      it "returns http success" do
        expect(subject).to be_successful
      end
    end

    describe "GET #index" do
      subject { get :index, params: default_params }
      it "returns http success" do
        expect(subject).to be_successful
      end

      it "sums distribution totals accurately" do
        distribution = create(:distribution, :with_items, item_quantity: 10)
        create(:distribution, :with_items, item_quantity: 5)
        create(:line_item, :distribution, itemizable_id: distribution.id, quantity: 7)
        subject
        expect(assigns(:total_items_all_distributions)).to eq(22)
        expect(assigns(:total_items_paginated_distributions)).to eq(22)
      end
    end

    describe "POST #create" do
      let!(:storage_location) { create(:storage_location) }
      let!(:partner) { create(:partner) }
      let(:distribution) do
        { distribution: { storage_location_id: storage_location.id, partner_id: partner.id } }
      end

      it "redirects to #index on success" do
        params = default_params.merge(distribution)
        expect(storage_location).to be_valid
        expect(partner).to be_valid
        expect(Flipper).to receive(:enabled?).with(:email_active).and_return(true)

        jobs_count = PartnerMailerJob.jobs.count

        post :create, params: params
        expect(response).to have_http_status(:redirect)

        expect(response).to redirect_to(distributions_path)
        expect(PartnerMailerJob.jobs.count).to eq(jobs_count + 1)
      end

      it "renders #new again on failure, with notice" do
        post :create, params: default_params.merge(distribution: { comment: nil, partner_id: nil, storage_location_id: nil })
        expect(response).to be_successful
        expect(response).to have_error
      end
    end

    describe "GET #new" do
      subject { get :new, params: default_params }
      it "returns http success" do
        expect(subject).to be_successful
      end
    end

    describe "GET #show" do
      subject { get :show, params: default_params.merge(id: create(:distribution).id) }
      it "returns http success" do
        expect(subject).to be_successful
      end
    end

    describe 'PATCH #picked_up' do
      subject { patch :picked_up, params: default_params.merge(id: distribution.id) }

      context 'when the distribution is successfully updated' do
        let(:distribution) { create(:distribution, state: 'scheduled') }

        it "updates the state to 'complete'" do
          subject
          expect(distribution.reload.state).to eq 'complete'
        end

        it 'redirects the user back to the distributions page' do
          expect(subject).to redirect_to distribution_path
        end
      end

      context 'when the distribution update fails' do
        let(:distribution) { create(:distribution, state: 'started') }

        it 'raises a warning' do
          expect(subject.request.flash[:error]).to_not be_nil
        end

        it 'redirects the user back to the distributions page' do
          expect(subject).to redirect_to distribution_path
        end
      end
    end

    context "Looking at a different organization" do
      let(:object) { create(:distribution, organization: create(:organization)) }
      include_examples "requiring authorization"
    end

    describe "POST #update" do
      let(:location) { create(:storage_location) }
      let(:partner) { create(:partner) }

      let(:distribution) { create(:distribution, partner: partner) }
      let(:issued_at) { distribution.issued_at }
      let(:distribution_params) do
        default_params.merge(
          id: distribution.id,
          distribution: {
            partner_id: partner.id,
            storage_location_id: location.id,
            'issued_at(1i)' => issued_at.to_date.year,
            'issued_at(2i)' => issued_at.to_date.month,
            'issued_at(3i)' => issued_at.to_date.day
          }
        )
      end

      subject { patch :update, params: distribution_params }

      it { expect(subject).to have_http_status(:ok) }

      describe "when changing storage location" do
        it "updates storage quantity correctly" do
          distribution = create(:distribution, :with_items, item_quantity: 10)
          original_storage_location = distribution.storage_location
          line_item = distribution.line_items.first
          new_storage_location = create(:storage_location)
          create(:donation, :with_items, item: line_item.item, item_quantity: 30, storage_location: new_storage_location)
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
            put :update, params: default_params.merge(id: distribution.id, distribution: distribution_params)
          end.to change { original_storage_location.size }.by(10) # removes the whole distribution of 10 - increasing inventory
          expect(new_storage_location.size).to eq 25
        end

        it "rollsback updates if quantity would go below 0" do
          distribution = create(:distribution, :with_items, item_quantity: 10)
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
            put :update, params: default_params.merge(id: donation.id, distribution: distribution_params)
          end.to raise_error(NameError)
          expect(original_storage_location.size).to eq 5
          expect(new_storage_location.size).to eq 0
          expect(distribution.reload.line_items.first.quantity).to eq 10
        end
      end

      context "mail follow up" do
        before { allow(Flipper).to receive(:enabled?).with(:email_active).and_return(true) }

        it { expect { subject }.not_to change { PartnerMailerJob.jobs.count } }

        context "sending" do
          let(:issued_at) { distribution.issued_at + 1.day }
          it { expect { subject }.to change { PartnerMailerJob.jobs.count } }
        end
      end
    end
  end

  context "While not signed in" do
    let(:object) { create(:distribution) }

    include_examples "requiring authorization"
  end
end
