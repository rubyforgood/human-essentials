RSpec.describe AdjustmentsController, type: :controller do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:storage_location) { create(:storage_location, organization: organization) }
  let(:item1) { create(:item, name: "Item One", organization: organization) }
  let(:item2) { create(:item, name: "Item Two", organization: organization) }

  let!(:adjustment1) do
    adj = create(:adjustment,
      organization: organization,
      storage_location: storage_location,
      comment: "First adjustment",
      created_at: 1.day.ago
    )
    adj.line_items << build(:line_item, quantity: 10, item: item1, itemizable: adj)
    adj.line_items << build(:line_item, quantity: 5, item: item2, itemizable: adj)
    adj
  end

  let!(:adjustment2) do
    adj = create(:adjustment,
      organization: organization,
      storage_location: storage_location,
      comment: "Second adjustment",
      created_at: 5.days.ago
    )
    adj.line_items << build(:line_item, quantity: -5, item: item1, itemizable: adj)
    adj
  end

  before do
    sign_in(user)
  end

  describe "GET #index" do
    context "with CSV format" do
      it "returns a CSV file" do
        get :index, format: :csv
        expect(response).to be_successful
        expect(response.header['Content-Type']).to include 'text/csv'
      end

      it "includes appropriate headers for adjustments" do
        get :index, format: :csv
        expect(response.body).to include("Created")
        expect(response.body).to include("Storage Location")
        expect(response.body).to include("Comment")
        expect(response.body).to include("User")
        expect(response.body).to include("Changes")
        expect(response.body).to include(item1.name)
        expect(response.body).to include(item2.name)
      end

      it "includes data from the adjustments" do
        get :index, format: :csv
        parsed_csv = CSV.parse(response.body, headers: true)

        expect(parsed_csv.count).to eq(2)

        expect(parsed_csv[0]["Comment"]).to eq(adjustment1.comment)
        expect(parsed_csv[1]["Comment"]).to eq(adjustment2.comment)

        expect(parsed_csv[0][item1.name]).to eq("10")
        expect(parsed_csv[0][item2.name]).to eq("5")
        expect(parsed_csv[0]["Changes"]).to eq("2")

        expect(parsed_csv[1][item1.name]).to eq("-5")
        expect(parsed_csv[1]["Changes"]).to eq("1")
      end

      context "when filtering by date" do
        it "returns adjustments filtered by date range" do
          start_date = 3.days.ago.to_fs(:date_picker)
          end_date = Time.zone.today.to_fs(:date_picker)

          get :index, params: { filters: { date_range: "#{start_date} - #{end_date}" } }, format: :csv

          parsed_csv = CSV.parse(response.body, headers: true)
          expect(parsed_csv.count).to eq(1)
          expect(assigns(:adjustments)).to include(adjustment1)
        end
      end
    end
  end
end
