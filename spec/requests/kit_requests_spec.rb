RSpec.describe "/kits", type: :request do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:organization_admin) { create(:organization_admin, organization: organization) }

  let!(:kit) {
    create_kit(organization: organization)
  }

  describe "while signed in" do
    before do
      sign_in(user)
    end

    describe "GET #show" do
      it "should redirect to the allocations page" do
        get kit_url(kit)
        expect(response).to redirect_to allocations_kit_path(kit.id)
      end
    end

    describe "GET #index" do
      before do
        # this shouldn't be shown
        create_kit(organization: organization, active: false, name: "DOOBIE KIT")
      end

      it "should include deactivate" do
        get kits_url
        expect(response).to be_successful
        page = Nokogiri::HTML(response.body)
        expect(response.body).not_to include("DOOBIE")
        expect(page.css(".deactivate-kit-button")).not_to be_empty
        expect(page.css(".reactivate-kit-button")).to be_empty
        expect(page.css(".deactivate-kit-button.disabled")).to be_empty
      end

      context "when it cannot be deactivated" do
        it "should disable the button" do
          storage_location = create(:storage_location)
          TestInventory.create_inventory(kit.organization, {
            storage_location.id => {
              kit.kit_item.id => 10
            }
          })
          get kits_url
          expect(response).to be_successful
          page = Nokogiri::HTML(response.body)
          expect(page.css(".deactivate-kit-button.disabled")).not_to be_empty
          expect(page.css(".reactivate-kit-button")).to be_empty
        end
      end

      context "when it is already deactivated" do
        it "should show reactivate button" do
          kit.deactivate
          get kits_url(include_inactive_items: true)
          expect(response).to be_successful
          page = Nokogiri::HTML(response.body)
          expect(page.css(".deactivate-kit-button")).to be_empty
          expect(page.css(".reactivate-kit-button")).not_to be_empty
        end
      end

      context "when show inactive is checked" do
        it "should show the inactive kit" do
          get kits_url(include_inactive_items: true)
          expect(response).to be_successful
          expect(response.body).to include("DOOBIE")
        end
      end
    end

    specify "PUT #deactivate" do
      expect(kit).to be_active
      put deactivate_kit_url(kit)
      expect(kit.reload).not_to be_active
      expect(response).to redirect_to(dashboard_path)
      expect(flash[:notice]).to eq("Kit has been deactivated!")
    end

    describe "PUT #reactivate" do
      it "cannot reactivate if it has an inactive item" do
        kit.deactivate
        expect(kit).not_to be_active
        kit.kit_item.line_items.first.item.update!(active: false)

        put reactivate_kit_url(kit)
        expect(kit.reload).not_to be_active
        expect(response).to redirect_to(dashboard_path)
        expect(flash[:alert]).to eq("Cannot reactivate kit - it has inactive items! Please reactivate the items first.")
      end

      it "should successfully reactivate" do
        kit.deactivate
        expect(kit).not_to be_active
        put reactivate_kit_url(kit)
        expect(kit.reload).to be_active
        expect(response).to redirect_to(dashboard_path)
        expect(flash[:notice]).to eq("Kit has been reactivated!")
      end
    end

    context "when accessing a kit from another organization" do
      let(:other_organization) { create(:organization) }
      let(:other_kit) { create_kit(organization: other_organization) }

      it "does not allow deactivating a kit from another organization" do
        put deactivate_kit_url(other_kit)
        expect(response.status).to eq(404)
      end

      it "does not allow reactivating a kit from another organization" do
        other_kit.deactivate
        put reactivate_kit_url(other_kit)
        expect(response.status).to eq(404)
      end

      it "does not allow viewing allocations for a kit from another organization" do
        get allocations_kit_url(other_kit)
        expect(response.status).to eq(404)
      end

      it "does not allow allocating for a kit from another organization" do
        storage_location = create(:storage_location, organization: organization)
        post allocate_kit_url(other_kit), params: {kit_adjustment: {storage_location_id: storage_location.id, change_by: 5}}
        expect(response.status).to eq(404)
      end
    end
  end
end
