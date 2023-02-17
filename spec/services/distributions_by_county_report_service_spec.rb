RSpec.describe DistributionByCountyReportService, type: :service do
  let(:organization) { create(:organization) }
  let(:year) { Time.current.year }
  let(:issued_at_last_year) { Time.current.utc.change(year: year - 1).to_datetime }
  let(:issued_at_present) { Time.current.utc.to_datetime }
  let(:item_1) { create(:item, value_in_cents: 1050) }
  let(:distributions) { [] }

  before do
    setup_overlapping_partners
    @storage_location = create(:storage_location, organization: @organization)
  end

  describe "get_breakdown" do
    it "will have 100% unspecified shows if no served_areas" do
      distribution_1 = create(:distribution, :with_items, item: item_1, organization: @user.organization)
      breakdown = DistributionByCountyReportService.new.get_breakdown([distribution_1])
      expect(breakdown.size).to eq(1)
      expect(breakdown[0].num_items).to eq(100)
      expect(breakdown[0].amount).to be_within(0.01).of(105000.0)
    end

    it "divides the item numbers and values according to the partner profile" do
      distribution_1 = create(:distribution, :with_items, item: item_1, organization: @user.organization, partner: @partner_1)
      breakdown = DistributionByCountyReportService.new.get_breakdown([distribution_1])
      expect(breakdown.size).to eq(5)
      expect(breakdown[4].num_items).to eq(0)
      expect(breakdown[4].amount).to be_within(0.01).of(0)
      (0..3).each do |i|
        expect(breakdown[i].num_items).to eq(25)
        expect(breakdown[i].amount).to be_within(0.01).of(26250.0)
      end
    end

    it "handles multiple partners with overlapping service areas properly" do
      distribution_p1 = create(:distribution, :with_items, item: item_1, organization: @user.organization, partner: @partner_1, issued_at: issued_at_present)
      distribution_p2 = create(:distribution, :with_items, item: item_1, organization: @user.organization, partner: @partner_2, issued_at: issued_at_present)
      breakdown = DistributionByCountyReportService.new.get_breakdown([distribution_p1, distribution_p2])
      num_with_45 = 0
      num_with_20 = 0
      num_with_0 = 0
      # The result will have at least 1 45 and at least 1 20, and 1 0.  Anything else will be either 45 or 25 or 20
      breakdown.each do |sa|
        if sa.num_items == 45
          expect(sa.amount).to be_within(0.01).of(47250.0)
          num_with_45 += 1
        end

        if sa.num_items == 25
          expect(sa.amount).to be_within(0.01).of(26250.0)
        end
        if sa.num_items == 20
          expect(sa.amount).to be_within(0.01).of(21000.0)
          num_with_20 += 1
        end
        if sa.num_items == 0
          expect(sa.amount).to be_within(0.01).of(0)
        end
      end
      expect(num_with_45).to be > 0
      expect(num_with_20).to be > 0
      expect(num_with_0).to eq 0
    end
  end

  def setup_overlapping_partners
    @partner_1 = create(:partner, organization: @organization)
    @partner_1.profile.served_areas << create_list(:partners_served_area, 4,
      partner_profile: @partner_1.profile, client_share: 25)
    @partner_2 = create(:partner, organization: @organization)
    @partner_2.profile.served_areas << create_list(:partners_served_area, 5,
      partner_profile: @partner_1.profile, client_share: 20)
    @partner_2.profile.served_areas[0].county = @partner_1.profile.served_areas[0].county
    @partner_2.profile.served_areas[0].save
    @partner_2.reload
  end
end
