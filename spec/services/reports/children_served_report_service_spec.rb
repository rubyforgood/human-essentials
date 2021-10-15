RSpec.describe Reports::ChildrenServedReportService, type: :service do
  describe "#children_served_by_partner" do
    it "counts the children from partner organizations" do
      family = create(:partners_family, partner: organization.partners.first.profile)
      create(:partners_child, family: family)

      expect(report.children_served_by_partner).to eq(1)
    end

    it "does't count the children from other organizations partners" do
      other_organization = create(:organization)
      create(:partner, organization_id: other_organization.id)
      family = create(:partners_family, partner: other_organization.partners.first.profile)
      create(:partners_child, family: family)

      expect(report.children_served_by_partner).to eq(0)
    end
  end

  describe "#monthly_children_served" do
    it "finds the monthly average number of children" do
      family = create(:partners_family, partner: organization.partners.first.profile)
      12.times { create(:partners_child, family: family) }

      expect(report.monthly_children_served).to eq("1")
    end
  end

  def organization
    @organization ||= create(:organization)
  end

  def report
    described_class.new(organization: organization, year: Time.zone.now.year)
  end
end
