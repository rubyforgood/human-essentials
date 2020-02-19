RSpec.describe TransfersController, type: :controller do
  context "While signed in" do
    before do
      sign_in(@user)
    end

    describe "GET #index" do
      around do |example|
        travel_to Time.zone.local(2019, 7, 1)
        example.run
        travel_back
      end

      subject { get :index, params: { organization_id: @organization.short_name } }
      it "returns http success" do
        expect(subject).to be_successful
      end

      context 'when filtering by date' do
        let!(:old_transfer) { create(:transfer, created_at: 7.days.ago) }
        let!(:new_transfer) { create(:transfer, created_at: 1.day.ago) }

        context 'when date parameters are supplied' do
          it 'only returns the correct obejects' do
            start_date = 3.days.ago.strftime "%m/%d/%Y"
            end_date = Time.zone.today.strftime "%m/%d/%Y"
            get :index, params: { organization_id: @organization.short_name, filters: { date_range: "#{start_date} - #{end_date}" } }
            expect(assigns(:transfers)).to eq([new_transfer])
          end
        end

        context 'when date parameters are not supplied' do
          it 'returns all objects' do
            get :index, params: { organization_id: @organization.short_name }
            expect(assigns(:transfers)).to eq([old_transfer, new_transfer])
          end
        end
      end
    end

    describe "POST #create" do
      it "redirects to #show when successful" do
        attributes = attributes_for(
          :transfer,
          organization_id: @organization.id,
          to_id: create(:storage_location, organization: @organization).id,
          from_id: create(:storage_location, organization: @organization).id
        )

        post :create, params: { organization_id: @organization.short_name, transfer: attributes }
        expect(response).to redirect_to(transfers_path)
      end

      it "renders to #new when failing" do
        post :create, params: { organization_id: @organization.short_name, transfer: { from_id: nil, to_id: nil } }
        expect(response).to be_successful # Will render :new
        expect(response).to render_template("new")
        expect(flash.keys).to match_array(['error'])
      end
    end

    describe "GET #new" do
      subject { get :new, params: { organization_id: @organization.short_name } }
      it "returns http success" do
        expect(subject).to be_successful
      end
    end

    describe "GET #show" do
      subject { get :show, params: { organization_id: @organization.short_name, id: create(:transfer, organization: @organization) } }
      it "returns http success" do
        expect(subject).to be_successful
      end
    end
    context "Looking at a different organization" do
      let(:object) do
        org = create(:organization)
        create(:transfer,
               to: create(:storage_location, organization: org),
               from: create(:storage_location, organization: org),
               organization: org)
      end
      include_examples "requiring authorization", except: %i(edit update destroy)
    end
  end

  context "While not signed in" do
    let(:object) { create(:transfer) }

    include_examples "requiring authorization", except: %i(edit update destroy)
  end
end
