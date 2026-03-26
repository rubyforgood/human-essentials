# frozen_string_literal: true

shared_examples_for "distribution_by_county" do
  let(:organization) { create(:organization, name: "Some Unique Name") }
  let(:user) { create(:user, organization: organization) }
  let(:organization_admin) { create(:organization_admin, organization: organization) }



  let(:item_1) { create(:item, value_in_cents: 1050, organization: organization, reporting_category: :cloth_diapers) }
  let(:item_2) { create(:item, value_in_cents: 20, organization: organization, reporting_category: :tampons) }
  let(:item_3) {create(:item, value_in_cents:75, organization: organization, reporting_category: :pads)}
  let(:item_4) {create(:item, value_in_cents:50, organization: organization, reporting_category: :pads)}

  let(:kit_a) {
    kita = create_kit(name: "Kit A", organization: organization, line_items_attributes: [
      {item_id: item_2.id, quantity: 40},
      {item_id: item_3.id, quantity: 20}
    ])



    #  kita = create(:kit, name: "Kit A")
    # kita.item.line_items = [
    #   create(:line_item, quantity: 40, item: item_2),
    #   create(:line_item, quantity: 20, item: item_3)
    # ]
    kita
  }

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
