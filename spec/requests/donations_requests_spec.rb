require "rails_helper"

RSpec.describe "Donations", type: :request do
  let(:default_params) do
    { organization_id: @organization.to_param }
  end

  describe "while signed in" do
    before do
      sign_in(@user)
    end

    describe "GET #index" do
      subject do
        get donations_path(default_params.merge(format: response_format))
        response
      end

      before do
        create(:donation)
      end

      context "html" do
        let(:response_format) { 'html' }

        it { is_expected.to be_successful }
      end

      context "csv" do
        let(:response_format) { 'csv' }

        it { is_expected.to be_successful }
      end
    end

    context "GET #edit" do
      context "when an finalized audit has been performed on the donated items" do
        it "shows a warning" do
          item = create(:item, organization: @organization, name: "Brightbloom Seed")
          storage_location = create(:storage_location, :with_items, item: item, organization: @organization)
          donation = create(:donation, :with_items, item: item, organization: @organization, storage_location: storage_location)
          create(:audit, :with_items, item: item, storage_location: storage_location, status: "finalized")

          get edit_donation_path(@organization.to_param, donation)

          expect(response.body).to include("You’ve had an audit since this donation was started.")
          expect(response.body).to include("In the case that you are correcting a typo, rather than recording that the physical amounts being donated have changed,\n")
          expect(response.body).to include("you’ll need to make an adjustment to the inventory as well.")
        end
      end
    end

    context "when an non-finalized audit has been performed on the donated items" do
      it "does not shows a warning" do
        item = create(:item, organization: @organization, name: "Brightbloom Seed")
        storage_location = create(:storage_location, :with_items, item: item, organization: @organization)
        donation = create(:donation, :with_items, item: item, organization: @organization, storage_location: storage_location)
        create(:audit, :with_items, item: item, storage_location: storage_location, status: "confirmed")

        get edit_donation_path(@organization.to_param, donation)

        expect(response.body).to_not include("You’ve had an audit since this donation was started.")
        expect(response.body).to_not include("In the case that you are correcting a typo, rather than recording that the physical amounts being donated have changed,\n")
        expect(response.body).to_not include("you’ll need to make an adjustment to the inventory as well.")
      end
    end

    context "when no audit has been performed" do
      it "doesn't show a warning" do
        item = create(:item, organization: @organization, name: "Brightbloom Seed")
        storage_location = create(:storage_location, :with_items, item: item, organization: @organization)
        donation = create(:donation, :with_items, item: item, organization: @organization, storage_location: storage_location)

        get edit_donation_path(@organization.to_param, donation)

        expect(response.body).to_not include("You’ve had an audit since this donation was started.")
        expect(response.body).to_not include("In the case that you are correcting a typo, rather than recording that the physical amounts being donated have changed,\n")
        expect(response.body).to_not include("you’ll need to make an adjustment to the inventory as well.")
      end
    end
  end
end
