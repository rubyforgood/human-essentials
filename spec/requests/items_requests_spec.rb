RSpec.describe "Items", type: :request do
  let(:organization) { create(:organization, short_name: "my_org") }
  let(:user) { create(:user, organization: organization) }

  describe "while signed in" do
    before do
      sign_in(user)
    end

    describe "GET #index" do
      subject do
        get items_path(format: response_format)
        response
      end

      before do
        create(:item)
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

    describe "GET #new" do
      it "shows the organization request_units options if they exist" do
        Flipper.enable(:enable_packs)
        organization_units = create_list(:unit, 3, organization: organization)
        get new_item_path
        organization_units.each do |unit|
          expect(response.body).to include unit.name
        end
      end
    end

    describe "GET #edit" do
      it "shows the selected request_units" do
        Flipper.enable(:enable_packs)
        organization_units = create_list(:unit, 3, organization: organization)
        selected_unit = organization_units.first
        item = create(:item, organization: organization)
        create(:item_unit, item: item, name: selected_unit.name)

        get edit_item_path(item)

        parsed_body = Nokogiri::HTML(response.body)
        checkboxes = parsed_body.css("input[type='checkbox'][name='item[request_unit_ids][]']")
        expect(checkboxes.length).to eq organization_units.length
        checkboxes.each do |checkbox|
          if checkbox['value'] == selected_unit.id.to_s
            expect(checkbox['checked']).to eq('checked')
          else
            expect(checkbox['checked']).to be_nil
          end
        end
      end
    end

    describe 'DELETE #deactivate' do
      let(:item) { create(:item, organization: organization, active: true) }
      let(:storage_location) { create(:storage_location, organization: organization) }
      let(:params) { {id: item.id} }

      it 'should be able to deactivate an item' do
        expect { delete deactivate_item_path(params) }.to change { item.reload.active }.from(true).to(false)
        expect(response).to redirect_to(items_path)
      end

      it 'should not be able to deactivate an item in a storage location' do
        TestInventory.create_inventory(
          organization,
          storage_location.id => {
            item.id => 100
          }
        )
        delete deactivate_item_path(params)
        expect(flash[:error]).to eq("Cannot deactivate item - it is in a storage location or kit!")
        expect(item.reload.active).to eq(true)
      end
    end

    describe 'DELETE #destroy' do
      let!(:item) { create(:item, organization: organization, active: true) }
      let(:storage_location) { create(:storage_location, organization: organization) }
      let(:params) { {id: item.id} }

      it 'should be able to delete an item' do
        expect { delete item_path(params) }.to change { Item.count }.by(-1)
        expect(response).to redirect_to(items_path)
      end

      it 'should not be able to delete an item in a storage location' do
        TestInventory.create_inventory(
          organization,
          storage_location.id => {
            item.id => 100
          }
        )
        expect { delete item_path(params) }.not_to change { Item.count }
        expect(flash[:error]).to eq("Cannot delete item - it has already been used!")
      end
    end

    describe "CREATE #create" do
      let!(:existing_item) { create(:item, organization: organization, name: "Really Good Item") }

      describe "with an already existing item name" do
        let(:item_params) do
          {
            item: {
              name: "really good item",
              partner_key: create(:base_item).partner_key,
              value_in_cents: 1001,
              package_size: 5,
              distribution_quantity: 30
            }
          }
        end

        it "shouldn't create an item with the same name" do
          expect { post items_path, params: item_params }.to_not change { Item.count }

          expect(flash[:error]).to eq("Name - An item with that name already exists (could be an inactive item)")
          expect(response).to render_template(:new)
        end
      end
    end

    describe 'GET #index' do
      let(:storage_location) { create(:storage_location, organization: organization) }
      let!(:item) { create(:item, organization: organization, name: "ACTIVEITEM") }
      let!(:non_deactivate_item) { create(:item, organization: organization, name: "NODEACTIVATE") }
      let!(:non_delete_item) { create(:item, organization: organization, name: "NODELETE") }
      let!(:inactive_item) { create(:item, organization: organization, active: false, name: "NOSIR") }

      before do
        TestInventory.create_inventory(organization, {
          storage_location.id => {
            non_deactivate_item.id => 5
          }
        })
        create(:adjustment, :with_items, organization: organization,
          item: non_delete_item, storage_location: storage_location)
      end

      it "should show all active items with corresponding buttons" do
        get items_path
        page = Nokogiri::HTML(response.body)
        expect(response.body).to include("ACTIVEITEM")
        expect(response.body).to include("NODEACTIVATE")
        expect(response.body).to include("NODELETE")
        expect(response.body).not_to include("NOSIR")
        button1 = page.css(".btn.btn-danger[href='/items/#{item.id}']")
        expect(button1.text.strip).to eq("Delete")
        button2 = page.css(".btn[href='/items/#{non_delete_item.id}/deactivate']")
        expect(button2.text.strip).to eq("Deactivate")
        expect(button2.attr('class')).not_to match(/disabled/)
        button3 = page.css(".btn[href='/items/#{non_deactivate_item.id}/deactivate']")
        expect(button3.text.strip).to eq("Deactivate")
        expect(button3.attr('class')).to match(/disabled/)
      end

      context "custom request items" do
        before(:each) { Flipper.enable(:enable_packs) }

        it "does not show the column if the organization does not use custom request units" do
          get items_path
          expect(response.body).not_to include("Custom Request Units")
        end

        it "shows the column if there are custom request units defined" do
          units = create_list(:unit, 3, organization:)
          units.each do |unit|
            create(:item_unit, item:, name: unit.name)
          end
          expect(item.request_units).not_to be_empty
          get items_path
          expect(response.body).to include("Custom Request Units")
          expect(response.body).to include(item.request_units.pluck(:name).join(', '))
        end
      end
    end

    describe 'GET #show' do
      let!(:base_item) { create(:base_item, name: 'BASEITEM') }
      let!(:item_category) { create(:item_category, name: 'CURRENTCATEGORY') }
      let!(:item) { create(:item, organization: organization, name: "ACTIVEITEM", item_category_id: item_category.id, distribution_quantity: 2000, on_hand_recommended_quantity: 2348, package_size: 100, value_in_cents: 20000, on_hand_minimum_quantity: 1200, visible_to_partners: true) }
      let!(:item_unit_1) { create(:item_unit, item: item, name: 'ITEM1') }
      let!(:item_unit_2) { create(:item_unit, item: item, name: 'ITEM2') }
      it 'shows complete item details except custom request' do
        get item_path(id: item.id)
        expect(response.body).to include('Base Item')
        expect(response.body).to include('BASEITEM')
        expect(response.body).to include('Name')
        expect(response.body).to include("ACTIVEITEM")
        expect(response.body).to include('Category')
        expect(response.body).to include('CURRENTCATEGORY')
        expect(response.body).to include('Value Per Item')
        expect(response.body).to include('20000')
        expect(response.body).to include('Quantity Per Indivudual')
        expect(response.body).to include('2000')
        expect(response.body).to include('On hand minimum quantity')
        expect(response.body).to include('1200')
        expect(response.body).to include('On hand recommended quantity')
        expect(response.body).to include('2348')
        expect(response.body).to include('Package Size')
        expect(response.body).to include('100')
        expect(response.body).not_to include('Custom Units')
        expect(response.body).not_to include("#ITEM1; ITEM2")
        expect(response.body).to include('Item is visible to partners')
        expect(response.body).to include('Yes')
      end

      it 'shows custom request units when flipper enabled' do
        Flipper.enable(:enable_packs)
        get item_path(id: item.id)
        print(response.body)
        expect(response.body).to include('Custom Units')
        expect(response.body).to include("ITEM1; ITEM2")
      end
    end
  end
end
