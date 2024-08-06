RSpec.describe "Purchases", type: :request do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:organization_admin) { create(:organization_admin, organization: organization) }

  context "While signed in as a user >" do
    before do
      sign_in(user)
    end

    describe "GET #index" do
      subject do
        get purchases_path(format: response_format)
        response
      end

      context "html" do
        let(:response_format) { 'html' }

        it "returns success when a purchase exists" do
          create(:purchase)
          expect(subject).to be_successful
        end

        it "shows the FMV column" do
          purchase = create(:purchase, amount_spent_in_cents: 1234, organization: organization)
          item = create(:item, value_in_cents: 42, organization: organization)
          create(:line_item, item: item, itemizable: purchase, quantity: 2)

          expect(subject.body).to include("FMV")
          expect(subject.body).to include("$0.84")
        end

        it "shows the Comments column" do
          create(:purchase, comment: "Purchase Comment", organization: organization)
          expect(subject.body).to include("Comments")
          expect(subject.body).to include("Purchase Comment")
        end
      end

      context "csv" do
        before { create(:purchase) }
        let(:response_format) { 'csv' }

        it { is_expected.to be_successful }
      end
    end

    describe "GET #new" do
      subject do
        get new_purchase_path
        response
      end

      it { is_expected.to be_successful }
    end

    describe "POST#create" do
      let!(:storage_location) { create(:storage_location, organization: organization) }
      let(:line_items) { [attributes_for(:line_item)] }
      let(:vendor) { create(:vendor, organization: organization) }

      context "on success" do
        let(:purchase) do
          { storage_location_id: storage_location.id,
            purchased_from: "Google",
            vendor_id: vendor.id,
            amount_spent: 10,
            line_items: line_items }
        end

        it "redirects to GET#edit" do
          expect { post purchases_path(purchase: purchase) }
            .to change { Purchase.count }.by(1)
            .and change { PurchaseEvent.count }.by(1)
          expect(response).to redirect_to(purchases_path)
        end

        it "accepts :amount_spent_in_cents with dollar signs, commas, and periods" do
          formatted_purchase = purchase.merge(amount_spent: "$1,000.54")
          post purchases_path(purchase: formatted_purchase)

          expect(Purchase.last.amount_spent_in_cents).to eq 100_054
        end

        it "storage location defaults to organizations storage location" do
          purchase = create(:purchase)
          get edit_purchase_path(purchase)
          expect(response.body).to match(/(<option selected="selected" value=")[0-9]*(">Smithsonian Conservation Center<\/option>)/)
        end
      end

      context "on failure" do
        it "renders GET#new with error" do
          post purchases_path(purchase: { storage_location_id: nil, amount_spent: nil })
          expect(response).to be_successful # Will render :new
          expect(response.body).to include('Failed to create purchase due to')
        end
      end
    end

    describe "PUT#update" do
      it "redirects to index after update" do
        purchase = create(:purchase, purchased_from: "Google")
        put purchase_path(id: purchase.id, purchase: { purchased_from: "Google" })
        expect(response).to redirect_to(purchases_path)
      end

      it "updates storage quantity correctly" do
        purchase = create(:purchase, :with_items, item_quantity: 5)
        line_item = purchase.line_items.first
        line_item_params = {
          "0" => {
            "_destroy" => "false",
            item_id: line_item.item_id,
            quantity: "10",
            id: line_item.id
          }
        }
        purchase_params = { source: "Purchase Site", line_items_attributes: line_item_params }
        expect do
          put purchase_path(id: purchase.id, purchase: purchase_params)
        end.to change { purchase.storage_location.inventory_items.first.quantity }.by(5)
          .and change {
            View::Inventory.new(organization.id)
              .quantity_for(storage_location: purchase.storage_location_id, item_id: line_item.item_id)
          }.by(5)
      end

      describe "when removing a line item" do
        it "updates storage invetory item quantity correctly" do
          purchase = create(:purchase, :with_items, item_quantity: 10)
          line_item = purchase.line_items.first
          line_item_params = {
            "0" => {
              "_destroy" => "true",
              item_id: line_item.item_id,
              id: line_item.id
            }
          }
          purchase_params = { source: "Purchase Site", line_items_attributes: line_item_params }
          expect do
            put purchase_path(id: purchase.id, purchase: purchase_params)
          end.to change { purchase.storage_location.inventory_items.first.quantity }.by(-10)
            .and change {
                   View::Inventory.new(organization.id)
                     .quantity_for(storage_location: purchase.storage_location_id, item_id: line_item.item_id)
                 }.by(-10)
        end
      end

      describe "when changing storage location" do
        it "updates storage quantity correctly" do
          purchase = create(:purchase, :with_items, item_quantity: 10)
          original_storage_location = purchase.storage_location
          new_storage_location = create(:storage_location)
          line_item = purchase.line_items.first
          line_item_params = {
            "0" => {
              "_destroy" => "false",
              item_id: line_item.item_id,
              quantity: "8",
              id: line_item.id
            }
          }
          purchase_params = { storage_location_id: new_storage_location.id, line_items_attributes: line_item_params }
          expect do
            put purchase_path(id: purchase.id, purchase: purchase_params)
          end.to change { original_storage_location.size }.by(-10) # removes the whole purchase of 10
          expect(new_storage_location.size).to eq 8
        end

        # TODO this test is invalid in event-world since it's handled by the aggregate
        it "rollsback updates if quantity would go below 0" do
          next if Event.read_events?(organization)

          purchase = create(:purchase, :with_items, item_quantity: 10)
          original_storage_location = purchase.storage_location

          # adjust inventory so that updating will set quantity below 0
          inventory_item = original_storage_location.inventory_items.last
          inventory_item.quantity = 5
          inventory_item.save!

          new_storage_location = create(:storage_location)
          line_item = purchase.line_items.first
          line_item_params = {
            "0" => {
              "_destroy" => "false",
              item_id: line_item.item_id,
              quantity: "1",
              id: line_item.id
            }
          }
          purchase_params = { storage_location: new_storage_location, line_items_attributes: line_item_params }
          put purchase_path(id: purchase.id, purchase: purchase_params)
          expect(response).not_to redirect_to(anything)
          expect(original_storage_location.size).to eq 5
          expect(new_storage_location.size).to eq 0
          expect(purchase.reload.line_items.first.quantity).to eq 10
        end
      end
    end

    describe "GET #edit" do
      let(:storage_location) { create(:storage_location, organization: organization) }

      it "returns http success" do
        get edit_purchase_path(id: create(:purchase, organization: organization))
        expect(response).to be_successful
      end

      it "storage location is correct" do
        storage2 = create(:storage_location, name: "storage2")
        purchase2 = create(:purchase, storage_location: storage2)
        get edit_purchase_path(purchase2)
        expect(response.body).to match(/(<option selected="selected" value=")[0-9]*(">storage2<\/option>)/)
      end

      context "when an finalized audit has been performed on the purchased items" do
        it "shows a warning" do
          item = create(:item, organization: organization, name: "Brightbloom Seed")
          storage_location = create(:storage_location, :with_items, item: item, organization: organization)
          purchase = create(:purchase, :with_items, item: item, storage_location: storage_location)
          create(:audit, :with_items, item: item, storage_location: storage_location, status: "finalized")

          get edit_purchase_path(purchase)

          expect(response.body).to include("You’ve had an audit since this purchase was started.")
          expect(response.body).to include("In the case that you are correcting a typo, rather than recording that the physical amounts being purchased have changed,")
          expect(response.body).to include("you’ll need to make an adjustment to the inventory as well.")
        end
      end

      context "when non-finalized audit has been performed on the purchased items" do
        it "does not show a warning" do
          item = create(:item, organization: organization, name: "Brightbloom Seed")
          storage_location = create(:storage_location, :with_items, item: item, organization: organization)
          purchase = create(:purchase, :with_items, item: item, storage_location: storage_location)
          create(:audit, :with_items, item: item, storage_location: storage_location, status: "confirmed")

          get edit_purchase_path(purchase)

          expect(response.body).to_not include("You’ve had an audit since this purchase was started.")
          expect(response.body).to_not include("In the case that you are correcting a typo, rather than recording that the physical amounts being purchased have changed,")
          expect(response.body).to_not include("you’ll need to make an adjustment to the inventory as well.")
        end
      end

      context "when no audit has been performed" do
        it "does not show a warning" do
          item = create(:item, organization: organization, name: "Brightbloom Seed")
          storage_location = create(:storage_location, :with_items, item: item, organization: organization)
          purchase = create(:purchase, :with_items, item: item, storage_location: storage_location)

          get edit_purchase_path(purchase)

          expect(response.body).to_not include("You’ve had an audit since this purchase was started.")
          expect(response.body).to_not include("In the case that you are correcting a typo, rather than recording that the physical amounts being purchased have changed,")
          expect(response.body).to_not include("you’ll need to make an adjustment to the inventory as well.")
        end
      end
    end

    describe "GET #show" do
      let(:item) { create(:item) }
      let!(:purchase) { create(:purchase, :with_items, item: item) }

      it "shows an enabled edit button" do
        get purchase_path(id: purchase.id)
        expect(response).to be_successful
        page = Nokogiri::HTML(response.body)
        edit = page.at_css("a[href='#{edit_purchase_path(id: purchase.id)}']")
        expect(edit.attr("class")).not_to match(/disabled/)
        expect(response.body).not_to match(/please make the following items active:/)
      end

      context "with an inactive item - non-organization admin user" do
        before do
          item.update(active: false)
        end

        it "shows a disabled edit button" do
          get purchase_path(id: purchase.id)
          page = Nokogiri::HTML(response.body)
          edit = page.at_css("a[href='#{edit_purchase_path(id: purchase.id)}']")
          expect(edit.attr("class")).to match(/disabled/)
          expect(response.body).to match(/please make the following items active: #{item.name}/)
        end
      end

      context "with an inactive item - organization admin user" do
        before do
          sign_in(organization_admin)
          item.update(active: false)
        end

        it "shows a disabled edit and delete buttons" do
          get purchase_path(purchase.id)
          page = Nokogiri::HTML(response.body)
          edit = page.at_css("a[href='#{edit_purchase_path(purchase.id)}']")
          delete = page.at_css("a.btn-danger[href='#{purchase_path(purchase.id)}']")
          expect(edit.attr("class")).to match(/disabled/)
          expect(delete.attr("class")).to match(/disabled/)
          expect(response.body).to match(/please make the following items active: #{item.name}/)
        end
      end
    end

    describe "DELETE #destroy" do
      # normal users are not authorized
      it "redirects to the dashboard" do
        delete purchase_path(id: create(:purchase, organization: organization))
        expect(response).to redirect_to(dashboard_path)
      end

      it "does not delete a purchase" do
        purchase = create(:purchase, purchased_from: "Google")
        expect { delete purchase_path(id: purchase.id) }.to_not change(Purchase, :count)
      end
    end
  end

  context "While signed in as an organizational admin" do
    before do
      sign_in(organization_admin)
    end

    describe "DELETE #destroy" do
      it "redirects to the index" do
        delete purchase_path(id: create(:purchase, organization: organization))
        expect(response).to redirect_to(purchases_path)
      end

      it "decreases storage location inventory" do
        purchase = create(:purchase, :with_items, item_quantity: 10)
        storage_location = purchase.storage_location
        expect { delete purchase_path(id: purchase.id) }.to change { storage_location.size }.by(-10)
      end

      it "deletes a purchase" do
        purchase = create(:purchase, purchased_from: "Google")
        expect { delete purchase_path(id: purchase.id) }.to change(Purchase, :count).by(-1)
      end

      it "displays the proper flash notice" do
        purchase_id = create(:purchase, purchased_from: "Google").id.to_s
        delete purchase_path(id: purchase_id)
        expect(response).to have_notice "Purchase #{purchase_id} has been removed!"
      end
    end
  end
end
