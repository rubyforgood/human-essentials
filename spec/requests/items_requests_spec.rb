require "rails_helper"

RSpec.describe "Items", type: :request do
  let(:default_params) do
    { organization_id: @organization.to_param }
  end

  describe "while signed in" do
    before do
      sign_in(@user)
    end

    describe "GET #index" do
      subject do
        get items_path(default_params.merge(format: response_format))
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

    describe 'PUT #update' do
      let(:item) { create(:item, organization: @organization, active: true) }
      let(:storage_location) { create(:storage_location, organization: @organization)}
      let(:kit) { create(:kit, organization: @organization) }
      let(:inactive_params) { default_params.merge({id: item.id, item: { active: false } }) }

      it 'should be able to deactivate an item' do
        expect { put item_path(inactive_params) }.to change { item.reload.active }.from(true).to(false)
        expect(response).to redirect_to(items_path)
      end

      it 'should not be able to deactivate an item in a storage location' do
        create(:inventory_item, storage_location: storage_location, item_id: item.id)
        put item_path(inactive_params)
        expect(flash[:error]).to eq("Can't deactivate this item - it is currently assigned to either an active kit or a storage location!")
        expect(item.reload.active).to eq(true)
      end

      it 'should not be able to deactivate an item in a kit' do
        create(:line_item, itemizable: kit, item_id: item.id)
        put item_path(inactive_params)
        expect(flash[:error]).to eq("Can't deactivate this item - it is currently assigned to either an active kit or a storage location!")
        expect(item.reload.active).to eq(true)
      end
    end
  end
end
