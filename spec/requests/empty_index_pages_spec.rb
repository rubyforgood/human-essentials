require "rails_helper"

# The audits index 500'd in the browser because its empty state called `filter_params`, a
# private method only about half the controllers define. Every request spec had records, so
# nothing ever rendered that branch.
#
# These walk every index with NO data, which is the state a brand-new organization is in.
RSpec.describe "Index pages with no data", type: :request do
  let(:organization) { create(:organization) }
  let(:user) { create(:organization_admin, organization: organization) }

  before { sign_in(user) }

  paths = {
    "donations" => "/donations",
    "purchases" => "/purchases",
    "requests" => "/requests",
    "distributions" => "/distributions",
    "items" => "/items",
    "kits" => "/kits",
    "storage locations" => "/storage_locations",
    "transfers" => "/transfers",
    "adjustments" => "/adjustments",
    "audits" => "/audits",
    "barcode items" => "/barcode_items",
    "partners" => "/partners",
    "donation sites" => "/donation_sites",
    "vendors" => "/vendors",
    "manufacturers" => "/manufacturers",
    "product drives" => "/product_drives",
    "product drive participants" => "/product_drive_participants"
  }.freeze

  paths.each do |name, path|
    it "renders the #{name} index" do
      get path
      expect(response).to be_successful
    end

    it "renders the #{name} index when a filter is applied" do
      get path, params: {filters: {by_name: "nothing matches this"}}
      expect(response).to be_successful
    end
  end
end
