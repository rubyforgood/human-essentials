RSpec.feature "Distributions", type: :system do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:storage_location) { create(:storage_location, organization: organization, name: "Test Storage Location") }
  let(:organization_admin) { create(:organization_admin, organization: organization) }
  let!(:partner) { create(:partner, organization: organization, name: "Test Partner") }

  before do
    sign_in(user)
    setup_storage_location(storage_location)
  end

  context "when filtering on the index page" do
    subject { distributions_path }
    let(:item_category) { create(:item_category) }
    let(:item1) { create(:item, name: "Good item", item_category: item_category, organization: organization) }
    let(:item2) { create(:item, name: "Crap item", organization: organization) }
    let(:partner1) { create(:partner, name: "This Guy", email: "thisguy@example.com", organization: organization) }
    let(:partner2) { create(:partner, name: "Not This Guy", email: "ntg@example.com", organization: organization) }

    it_behaves_like "Date Range Picker", Distribution, :issued_at
  end
end
