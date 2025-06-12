# frozen_string_literal: true

shared_examples_for "distribution_by_county" do
  let(:organization) { create(:organization, name: "Some Unique Name") }
  let(:user) { create(:user, organization: organization) }
  let(:organization_admin) { create(:organization_admin, organization: organization) }

  let(:item_1) { create(:item, value_in_cents: 1050, organization: organization) }
  let(:issued_at_present) { Time.current.to_datetime }
  let(:partner_1) {
    p1 = create(:partner, organization: organization)
    counties = [*1..4].map { |n| create(:county, name: "Partner 1 Test County #{n}") }
    p1.profile.served_areas << counties.map { |county| create(:partners_served_area, partner_profile: p1.profile, client_share: 25, county: county) }
    p1
  }
  let(:partner_2) {
    p2 = create(:partner, organization: organization)
    counties = [*1..5].map { |n| create(:county, name: "Partner 2 Test County #{n}") }
    p2.profile.served_areas << counties.map { |county| create(:partners_served_area, partner_profile: p2.profile, client_share: 20, county: county) }
    p2.profile.served_areas[0].county = partner_1.profile.served_areas[0].county
    p2.profile.served_areas[0].save
    p2.reload
    p2
  }
end
