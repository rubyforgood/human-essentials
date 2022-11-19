require "rails_helper"

RSpec.describe "/kits", type: :request do
  let(:default_params) do
    {organization_id: @organization.to_param}
  end
  let!(:kit) { create(:kit, :with_item, organization: @organization) }

  describe "while signed in" do
    before do
      sign_in(@user)
    end

    describe "GET #index" do
      before do
        # this shouldn't be shown
        create(:kit, :with_item, active: false, name: "DOOBIE KIT", organization: @organization)
      end

      it "should include deactivate" do
        get kits_url(default_params)
        expect(response).to be_successful
        page = Nokogiri::HTML(response.body)
        expect(response.body).not_to include("DOOBIE")
        expect(page.css(".deactivate-kit-button")).not_to be_empty
        expect(page.css(".reactivate-kit-button")).to be_empty
        expect(page.css(".deactivate-kit-button.disabled")).to be_empty
      end

      context "when it cannot be deactivated" do
        it "should disable the button" do
          create(:inventory_item, item: kit.item)
          get kits_url(default_params)
          expect(response).to be_successful
          page = Nokogiri::HTML(response.body)
          expect(page.css(".deactivate-kit-button.disabled")).not_to be_empty
          expect(page.css(".reactivate-kit-button")).to be_empty
        end
      end

      context "when it is already deactivated" do
        it "should show reactivate button" do
          kit.deactivate
          get kits_url(default_params.merge(include_inactive_items: true))
          expect(response).to be_successful
          page = Nokogiri::HTML(response.body)
          expect(page.css(".deactivate-kit-button")).to be_empty
          expect(page.css(".reactivate-kit-button")).not_to be_empty
        end
      end

      context "when show inactive is checked" do
        it "should show the inactive kit" do
          get kits_url(default_params.merge(include_inactive_items: true))
          expect(response).to be_successful
          expect(response.body).to include("DOOBIE")
        end
      end
    end

    specify "PUT #deactivate" do
      expect(kit).to be_active
      put deactivate_kit_url(kit, default_params)
      expect(kit.reload).not_to be_active
      expect(response).to redirect_to(dashboard_path)
      expect(flash[:notice]).to eq("Kit has been deactivated!")
    end

    specify "PUT #reactivate" do
      kit.deactivate
      expect(kit).not_to be_active
      put reactivate_kit_url(kit, default_params)
      expect(kit.reload).to be_active
      expect(response).to redirect_to(dashboard_path)
      expect(flash[:notice]).to eq("Kit has been reactivated!")
    end
  end
end
