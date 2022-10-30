require "rails_helper"

describe OrganizationUpdateService, skip_seed: true do
  let(:organization) { create(:organization) }

  describe "#update" do
    context "when object is valid" do
      it "should update and return true" do
        result = described_class.update(organization, {name: "A brand NEW NEW name"})
        expect(result).to eq(true)
        expect(organization.reload.name).to eq("A brand NEW NEW name")
      end
    end

    context "when object is invalid" do
      it "should not update and return false" do
        result = described_class.update(organization, {name: "A brand NEW NEW name",
                                                        url: "something that IS NOT A URL"})
        expect(result).to eq(false)
        expect(organization.reload.name).not_to eq("A brand NEW NEW name")
      end
    end
  end

  describe "#update_partner_flags" do
    before(:each) do
      partners = create_list(:partner, 2, organization: organization)
      partners.each { |p|
        p.profile.update!(
          enable_individual_requests: true,
          enable_child_based_requests: true
        )
      }
    end

    context "when field hasn't changed" do
      it "should not update partners" do
        described_class.update_partner_flags(organization)
        expect(organization.partners.map { |p| p.profile.enable_child_based_requests })
          .to eq([true, true])
        expect(organization.partners.map { |p| p.profile.enable_individual_requests })
          .to eq([true, true])
      end
    end

    context "when field has changed" do
      it "should update partners" do
        organization.update!(enable_child_based_requests: false, enable_individual_requests: false)
        described_class.update_partner_flags(organization)
        expect(organization.partners.map { |p| p.profile.enable_child_based_requests })
          .to eq([false, false])
        expect(organization.partners.map { |p| p.profile.enable_individual_requests })
          .to eq([false, false])
      end
    end
  end
end
