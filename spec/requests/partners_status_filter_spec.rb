require "rails_helper"

# The status filter's first option is "Active", which submits by_status="". Filterable#class_filter
# skips blank values, so without the guard in PartnersController#index that lands on every partner
# including deactivated ones -- the option would show more than its label promises.
RSpec.describe "Partners status filter", type: :request do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }

  before do
    sign_in(user)
    create(:partner, organization: organization, name: "Active Partner", status: :approved)
    create(:partner, organization: organization, name: "Gone Partner", status: :deactivated)
  end

  it "treats a blank status as unfiltered, matching the Active option's label" do
    get partners_path
    expect(response.body).to include("Active Partner")
    expect(response.body).not_to include("Gone Partner")

    get partners_path, params: {filters: {by_status: ""}}
    expect(response.body).to include("Active Partner")
    expect(response.body).not_to include("Gone Partner")
  end

  it "still filters to a named status" do
    get partners_path, params: {filters: {by_status: "deactivated"}}
    expect(response.body).to include("Gone Partner")
    expect(response.body).not_to include("Active Partner")
  end
end
