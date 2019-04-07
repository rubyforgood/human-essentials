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
    end

    describe "POST #create" do
      it "redirects to #index on success" do
        i = create(:storage_location)
        p = create(:partner)

        expect(i).to be_valid
        expect(p).to be_valid
        expect(Flipper).to receive(:enabled?).with(:email_active).and_return(true)

        jobs_count = PartnerMailerJob.jobs.count

        post :create, params: default_params.merge(distribution: { storage_location_id: i.id, partner_id: p.id })
        expect(response).to have_http_status(:redirect)

        expect(response).to redirect_to(distributions_path)
        expect(PartnerMailerJob.jobs.count).to eq(jobs_count + 1)
      end

      it "renders #new again on failure, with notice" do
        post :create, params: default_params.merge(distribution: { comment: nil, partner_id: nil, storage_location_id: nil })
        expect(response).to be_successful
        expect(flash[:error]).to match(/error/i)
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
