require "rails_helper"

RSpec.describe "Events", type: :request do
  let(:organization) { create(:organization) }
  let(:user) { create(:organization_admin, organization: organization) }
  let(:default_params) do
    {organization_id: organization.to_param}
  end

  context "When signed in" do
    before { sign_in(user) }

    describe "GET #index" do
      subject do
        get events_path(default_params.merge(format: response_format))
        response
      end

      before do
        item = create(:item, organization: organization, name: "Item1")
        donation = create(:donation, :with_items, organization: organization, item: item, item_quantity: 66)
        DonationEvent.publish(donation)

        # too old
        travel(-1.year) do
          donation = create(:donation, :with_items, organization: organization, item: item, item_quantity: 4954)
          DonationEvent.publish(donation)
        end
      end

      context "html" do
        let(:response_format) { "html" }

        it "should be successful" do
          subject
          expect(response.body).to include("Item1")
          expect(response.body).to include("66")
          expect(response.body).not_to include("4954")
        end
      end
    end
  end

  context "When not signed" do
    let(:object) { create(:event) }

    include_examples "requiring authorization"
  end
end
