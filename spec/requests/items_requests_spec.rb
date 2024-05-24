require "rails_helper"

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
    end
  end
end
