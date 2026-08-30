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
        # The disabled state is an attribute, not a class: the design system's button classes
        # carry Tailwind `disabled:` variants, so a class match would hit in both states.
        expect(page.css(".deactivate-kit-button[disabled]")).to be_empty
      end

      describe "PUT #deactivate when it cannot be deactivated" do
        it "says why, and what to do next" do
          storage_location = create(:storage_location)
          TestInventory.create_inventory(kit.organization, {storage_location.id => {kit.id => 10}})

          put deactivate_kit_path(kit)

          # The reason the action is offered rather than greyed out: a flash can name the kit, say
          # why, and end with the next step. `Kit` is an `Item` by STI, so this is Item#deactivate!.
          expect(flash[:alert]).to include(kit.name)
          expect(flash[:alert]).to include("Move or distribute the remaining stock")
          expect(kit.reload).to be_active
        end
      end

      context "when it cannot be deactivated" do
        # The action is *offered* rather than greyed out -- design.md: an action unavailable
        # because of the record's state is attempted and answered, because the server's flash can
        # say why and what to do next and a disabled item cannot. `/items` already worked this way;
        # kits was the last table that did not. The controller spec below covers the answer.
        it "still offers the action, without a confirmation" do
          storage_location = create(:storage_location)
          TestInventory.create_inventory(kit.organization, {
            storage_location.id => {
              kit.id => 10
            }
          })
          get kits_url
          expect(response).to be_successful
          page = Nokogiri::HTML(response.body)
          expect(page.css(".deactivate-kit-button")).not_to be_empty
          expect(page.css(".deactivate-kit-button[disabled]")).to be_empty
          # No "are you sure?" for something that cannot happen: it is two steps to a dead end.
          expect(page.css(".deactivate-kit-button[data-confirm]")).to be_empty
          expect(page.css(".reactivate-kit-button")).to be_empty
        end
      end

      context "when it is already deactivated" do
        it "should show reactivate button" do
          kit.deactivate!
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
        kit.deactivate!
        expect(kit).not_to be_active
        kit.line_items.first.item.update!(active: false)

        put reactivate_kit_url(kit)
        expect(kit.reload).not_to be_active
        expect(response).to redirect_to(dashboard_path)
        expect(flash[:alert]).to eq("Cannot reactivate kit - it has inactive items! Please reactivate the items first.")
      end

      it "should successfully reactivate" do
        kit.deactivate!
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
        other_kit.deactivate!
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
