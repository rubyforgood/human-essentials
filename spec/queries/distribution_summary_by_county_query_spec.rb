RSpec.describe DistributionSummaryByCountyQuery do
  let(:organization) { create(:organization, name: "Some Unique Name") }
  let(:item_1) { create(:item, value_in_cents: 1050, organization: organization) }
  let(:partner_1) do
    create(:partner, organization:, without_profile: true) do |p|
      p.profile = create(:partner_profile, partner: p, organization:) do |pp|
        pp.served_areas = create_list(:partners_served_area, 4, partner_profile: pp, client_share: 25) do |sa|
          sa.county = create(:county)
        end
      end
    end
  end
  let(:partner_2) do
    create(:partner, organization:, without_profile: true) do |p|
      p.profile = create(:partner_profile, partner: p, organization:) do |pp|
        pp.served_areas = create_list(:partners_served_area, 5, partner_profile: pp, client_share: 20) do |sa, i|
          # create one overlapping service area
          sa.county = i.zero? ? partner_1.profile.served_areas[0].county : create(:county)
        end
      end
    end
  end

  let(:now) { Time.current.to_datetime }

  let(:params) { {organization_id: organization.id, start_date: nil, end_date: nil} }

  describe "call" do
    it "will have 100% unspecified shows if no served_areas" do
      create(:distribution, :with_items, item: item_1, organization: organization)
      breakdown = DistributionSummaryByCountyQuery.new(**params).call
      expect(breakdown.size).to eq(1)
      expect(breakdown[0]["quantity"]).to eq(100)
      expect(breakdown[0]["amount"]).to be_within(0.01).of(105000.0)
    end

    it "divides the item numbers and values according to the partner profile" do
      create(:distribution, :with_items, item: item_1, organization: organization, partner: partner_1)
      breakdown = DistributionSummaryByCountyQuery.new(**params).call
      expect(breakdown.size).to eq(5)
      expect(breakdown[4]["quantity"]).to eq(0)
      expect(breakdown[4]["amount"]).to be_within(0.01).of(0)
      3.times do |i|
        expect(breakdown[i]["quantity"]).to eq(25)
        expect(breakdown[i]["amount"]).to be_within(0.01).of(26250.0)
      end
    end

    it "handles multiple partners with overlapping service areas properly" do
      create(:distribution, :with_items, item: item_1, organization: organization, partner: partner_1, issued_at: now)
      create(:distribution, :with_items, item: item_1, organization: organization, partner: partner_2, issued_at: now)
      breakdown = DistributionSummaryByCountyQuery.new(**params).call
      num_with_45 = 0
      num_with_20 = 0
      num_with_0 = 0
      # The result will have at least 1 45 and at least 1 20, and 1 0.  Anything else will be either 45 or 25 or 20
      breakdown.each do |sa|
        if sa["quantity"] == 45
          expect(sa["amount"]).to be_within(0.01).of(47250.0)
          num_with_45 += 1
        end

        if sa["quantity"] == 25
          expect(sa["amount"]).to be_within(0.01).of(26250.0)
        end
        if sa["quantity"] == 20
          expect(sa["amount"]).to be_within(0.01).of(21000.0)
          num_with_20 += 1
        end
        if sa["quantity"] == 0
          expect(sa["amount"]).to be_within(0.01).of(0)
        end
      end
      expect(num_with_45).to be > 0
      expect(num_with_20).to be > 0
      expect(num_with_0).to eq 0
    end
  end
end
