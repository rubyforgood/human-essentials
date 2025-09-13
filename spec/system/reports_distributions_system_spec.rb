RSpec.describe "Reports Distributions", type: :request do
  let(:organization) { create(:organization) }
  let(:storage_location) { create(:storage_location, name: "Pawane Location", organization: organization) }
  let(:user) { create(:user, organization: organization) }
  let(:organization_admin) { create(:organization_admin, organization: organization) }

  describe "while signed in" do
    before do
      sign_in(user)
    end

    describe "Distributions - Itemized" do
      let(:product_drive) { create(:product_drive, organization:) }
      let(:storage_location) { create(:storage_location, organization:) }
      let(:manufacturer) { create(:manufacturer, organization:) }
      let(:source) { Donation::SOURCES[:manufacturer] }
      let(:issued_at) { Date.yesterday }
      let(:money_raised) { 5 }
      let(:item) { create(:item, organization:) }

      let(:params) do
        {
          donation: {
            source: Donation::SOURCES[:manufacturer],
            manufacturer_id: manufacturer.id,
            product_drive_id: product_drive.id,
            storage_location_id: storage_location.id,
            money_raised_in_dollars: money_raised,
            product_drive_participant_id: nil,
            comment: "",
            issued_at: issued_at,
            line_items_attributes: {
              "0": {item_id: item.id, quantity: 10}
            }
          }
        }
      end

      let!(:partner) { create(:partner, organization: organization) }
      let(:distribution) do
        {
          storage_location_id: storage_location.id,
          partner_id: partner.id,
          issued_at:,
          delivery_method: :delivery,
          line_items_attributes: {
            "0": {item_id: item.id, quantity: 10}
          }
        }
      end

      it "Ensuring that the result of the distribution index is zero instead of Unknow" do
        post donations_path(params)
        expect(response).to redirect_to(donations_path)

        post distributions_path(distribution:, format: :turbo_stream)
        expect(response).to have_http_status(:redirect)

        get reports_itemized_distributions_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Total On Hand")
        page = Nokogiri::HTML(response.body)
        page.css("table tbody tr td:last-child").each do |item|
          expect(item.content.strip).to eq("0")
        end
      end

      it "Ensuring that the result of the donation index is zero instead of Unknow" do
        post donations_path(params)
        expect(response).to redirect_to(donations_path)

        post distributions_path(distribution:, format: :turbo_stream)
        expect(response).to have_http_status(:redirect)

        get reports_itemized_donations_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Total On Hand")
        page = Nokogiri::HTML(response.body)
        page.css("table tbody tr td:last-child").each do |item|
          expect(item.content.strip).to eq("0")
        end
      end
    end
  end
end
