# frozen_string_literal: true

shared_examples_for "distribution_by_county" do
  let(:organization) { create(:organization, name: "Some Unique Name") }
  let(:user) { create(:user, organization: organization) }
  let(:organization_admin) { create(:organization_admin, organization: organization) }

  let(:item_1) { create(:item, value_in_cents: 1050, organization: organization) }
  let(:issued_at_present) { Time.current.utc.to_datetime }
  let(:partner_1) {
    p1 = create(:partner, organization: organization)
    p1.profile.served_areas << create_list(:partners_served_area, 4, partner_profile: p1.profile, client_share: 25)
    p1
  }
  let(:partner_2) {
    p2 = create(:partner, organization: organization)
    p2.profile.served_areas << create_list(:partners_served_area, 5, partner_profile: partner_1.profile, client_share: 20)
    p2.profile.served_areas[0].county = partner_1.profile.served_areas[0].county
    p2.profile.served_areas[0].save
    p2.reload
    p2
  }
end
