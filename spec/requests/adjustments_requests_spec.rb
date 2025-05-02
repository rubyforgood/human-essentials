RSpec.describe "Adjustments", :wip, type: :request do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }

  # This should return the minimal set of attributes required to create a valid
  # Adjustment. As you add validations to Adjustment, be sure to
  # adjust the attributes here as well.
  let(:valid_attributes) do
    {
      organization_id: organization.id,
      storage_location_id: create(:storage_location, organization: organization).id
    }
  end

  let(:invalid_attributes) do
    { organization_name: nil }
  end

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # AdjustmentsController. Be sure to keep this updated too.
  let(:valid_session) { {} }

  let(:adjustment) { Adjustment.create! valid_attributes.merge(user_id: user.id) }

  describe "while signed in" do
    before do
      sign_in(user)
    end

    describe "GET #index" do
      subject do
        get adjustments_path(format: response_format)
        response
      end

      around do |example|
        travel_to Time.zone.local(2019, 7, 1)
        example.run
        travel_back
      end

      context "html" do
        let(:response_format) { 'html' }

        it "is successful" do
          adjustment
          expect(subject).to be_successful
        end

        include_examples "restricts access to organization users/admins"

        context 'when filtering by date' do
          let!(:old_adjustment) { create(:adjustment, created_at: 7.days.ago) }
          let!(:new_adjustment) { create(:adjustment, created_at: 1.day.ago) }

          context 'when date parameters are supplied' do
            it 'only returns the correct objects' do
              get adjustments_path(filters: { date_range: date_range_picker_params(3.days.ago, Time.zone.today) })
              expect(assigns(:adjustments)).to contain_exactly(new_adjustment)
            end
          end

          context 'when date parameters are not supplied' do
            it 'returns all objects' do
              get adjustments_path
              expect(assigns(:adjustments)).to contain_exactly(old_adjustment, new_adjustment)
            end
          end
        end
      end

      context "csv" do
        let(:response_format) { 'csv' }
        let(:storage_location) { create(:storage_location, organization: organization) }
        let(:item1) { create(:item, name: "Item One", organization: organization) }
        let(:item2) { create(:item, name: "Item Two", organization: organization) }

        let!(:adjustment1) do
          adj = create(:adjustment,
            organization: organization,
            storage_location: storage_location,
            comment: "First adjustment",
            created_at: 1.day.ago)
          adj.line_items << build(:line_item, quantity: 10, item: item1, itemizable: adj)
          adj.line_items << build(:line_item, quantity: 5, item: item2, itemizable: adj)
          adj
        end

        let!(:adjustment2) do
          adj = create(:adjustment,
            organization: organization,
            storage_location: storage_location,
            comment: "Second adjustment",
            created_at: 5.days.ago)
          adj.line_items << build(:line_item, quantity: -5, item: item1, itemizable: adj)
          adj
        end

        before { get adjustments_path(format: 'csv') }

        it "returns a CSV file" do
          expect(response).to be_successful
          expect(response.header['Content-Type']).to include 'text/csv'
        end

        it "includes appropriate headers for adjustments" do
          expect(response.body).to include("Created date")
          expect(response.body).to include("Storage Area")
          expect(response.body).to include("Comment")
          expect(response.body).to include("# of changes")
          expect(response.body).to include(item1.name)
          expect(response.body).to include(item2.name)
        end

        it "includes data from the adjustments" do
          parsed_csv = CSV.parse(response.body, headers: true)

          expect(parsed_csv.count).to eq(2)

          expect(parsed_csv[0]["Comment"]).to eq(adjustment1.comment)
          expect(parsed_csv[1]["Comment"]).to eq(adjustment2.comment)

          expect(parsed_csv[0][item1.name]).to eq("10")
          expect(parsed_csv[0][item2.name]).to eq("5")
          expect(parsed_csv[0]["# of changes"]).to eq("2")

          expect(parsed_csv[1][item1.name]).to eq("-5")
          expect(parsed_csv[1]["# of changes"]).to eq("1")
        end

        context "when filtering by date" do
          it "returns adjustments filtered by date range" do
            start_date = 3.days.ago.to_fs(:date_picker)
            end_date = Time.zone.today.to_fs(:date_picker)

            get adjustments_path, params: { filters: { date_range: "#{start_date} - #{end_date}" }, format: 'csv' }

            parsed_csv = CSV.parse(response.body, headers: true)
            expect(parsed_csv.count).to eq(1)
            expect(parsed_csv[0]["Comment"]).to eq(adjustment1.comment)
          end
        end
      end
    end

    describe "GET #show" do
      subject do
        get adjustment_path(adjustment)
        response
      end

      it { is_expected.to be_successful }
    end

    describe "GET #new" do
      it "is successful" do
        get new_adjustment_path
        expect(response).to be_successful
      end
    end

    describe "POST #create" do
      context "with valid params" do
        it "creates a new Adjustment" do
          expect do
            post adjustments_path(adjustment: valid_attributes)
          end.to change(Adjustment, :count).by(1)
            .and change(AdjustmentEvent, :count).by(1)
        end

        it "assigns a newly created adjustment as @adjustment" do
          post adjustments_path(adjustment: valid_attributes)
          expect(assigns(:adjustment)).to be_a(Adjustment)
          expect(assigns(:adjustment)).to be_persisted
        end

        it "assigns a user id from the current user" do
          post adjustments_path(adjustment: valid_attributes)
          expect(assigns(:adjustment).user_id).to eq(user.id)
        end

        it "redirects to the #show after created adjustment" do
          post adjustments_path(adjustment: valid_attributes)
          expect(response).to redirect_to(adjustment_path(Adjustment.last))
        end
      end

      context "with invalid params" do
        it "assigns a newly created but unsaved adjustment as @adjustment" do
          post adjustments_path(adjustment: invalid_attributes)
          expect(assigns(:adjustment)).to be_a_new(Adjustment)
        end

        it "re-renders the 'new' template" do
          post adjustments_path(adjustment: invalid_attributes)
          expect(response).to render_template("new")
        end
      end
    end
  end
end
