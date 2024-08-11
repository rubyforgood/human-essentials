RSpec.describe "Partners profile served area behaviour", type: :system, js: true do
  let(:organization) { create(:organization) }
  let(:partner) { create(:partner, organization: organization) }
  let(:partner_user) { partner.primary_user }

  before(:each) do
    sign_in(partner_user)
  end

  describe "GET #index" do
    let!(:item1) { FactoryBot.create(:item, organization: organization, name: "Item 1") }
    let!(:item2) { FactoryBot.create(:item, organization: organization, name: "Item 2") }
    before(:each) do
      FactoryBot.create(:item_unit, name: "pack", item: item1)
    end

    context "with packs off" do
      before(:each) do
        Flipper.disable(:enable_packs)
      end

      it "should not show packs on selection" do
        visit new_partners_request_path
        select "Item 1", from: "request_item_requests_attributes_0_item_id"
        expect(page).not_to have_selector("#request_item_requests_attributes_0_request_unit", visible: true)
      end
    end

    context "with packs on" do
      before(:each) do
        Flipper.enable(:enable_packs)
      end

      it "should show packs on selection" do
        visit new_partners_request_path
        expect(Request.count).to eq(0)
        expect(page).not_to have_selector("#request_item_requests_attributes_0_request_unit", visible: true)
        select "Item 1", from: "request_item_requests_attributes_0_item_id"
        expect(page).to have_selector("#request_item_requests_attributes_0_request_unit", visible: true)
        expect(page).to have_select("request_item_requests_attributes_0_request_unit", selected: "Units", options: ["Units", "packs"])
        select "packs", from: "request_item_requests_attributes_0_request_unit"
        click_on "Add Another Item"

        # get selector to use in subsequent steps
        new_item = find_all(:css, "select[data-item-units-target=itemSelect]")[1]
        id = new_item[:id].match(/\d+/)[0]

        expect(page).not_to have_selector("request_item_requests_attributes_#{id}_request_unit", visible: true)
        select "Item 2", from: "request_item_requests_attributes_#{id}_item_id"
        expect(page).not_to have_selector("request_item_requests_attributes_#{id}_request_unit", visible: true)
        fill_in "request_item_requests_attributes_0_quantity", with: 50
        fill_in "request_item_requests_attributes_#{id}_quantity", with: 20
        click_on "Submit Essentials Request"

        expect(Request.count).to eq(1)
        request = Request.last
        expect(request.item_requests[0].quantity).to eq("50")
        expect(request.item_requests[0].item_id).to eq(item1.id)
        expect(request.item_requests[0].request_unit).to eq("pack")
        expect(request.item_requests[1].quantity).to eq("20")
        expect(request.item_requests[1].item_id).to eq(item2.id)
        expect(request.item_requests[1].request_unit).to eq(nil)
      end
    end
  end
end
