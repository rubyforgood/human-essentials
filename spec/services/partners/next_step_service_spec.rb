require "rails_helper"

RSpec.describe Partners::NextStepService, type: :service do
  describe "#call" do
    context "when the partner has all dynamic partials available" do
      let(:partner) { create(:partner) }

      it "returns next static section given first static section" do
        expect(described_class.new(partner, "agency_information").call).to eq("program_delivery_address")
      end

      it "returns first dynamic section given second static section" do
        expect(described_class.new(partner, "program_delivery_address").call).to eq("media_information")
      end

      it "returns next dynamic section given first dynamic section" do
        expect(described_class.new(partner, "media_information").call).to eq("agency_stability")
        expect(described_class.new(partner, "agency_stability").call).to eq("organizational_capacity")
        expect(described_class.new(partner, "organizational_capacity").call).to eq("sources_of_funding")
      end

      it "returns last static section given last dynamic section" do
        expect(described_class.new(partner, "attached_documents").call).to eq("partner_settings")
      end

      it "returns first static section given last static section" do
        expect(described_class.new(partner, "partner_settings").call).to eq("agency_information")
      end
    end

    context "when the partner has restricted partials" do
      let(:partner) { create(:partner, organization: restricted_organization) }
      let(:restricted_organization) { create(:organization, partner_form_fields: ["agency_stability", "population_served", "pick_up_person"]) }

      it "returns next static section given first static section" do
        expect(described_class.new(partner, "agency_information").call).to eq("program_delivery_address")
      end

      it "returns first dynamic section from restricted list, given second static section" do
        expect(described_class.new(partner, "program_delivery_address").call).to eq("agency_stability")
      end

      it "returns next dynamic section given a dynamic section from restricted list" do
        expect(described_class.new(partner, "agency_stability").call).to eq("population_served")
        expect(described_class.new(partner, "population_served").call).to eq("pick_up_person")
      end

      it "returns last static section given last dynamic section from restricted list" do
        expect(described_class.new(partner, "pick_up_person").call).to eq("partner_settings")
      end

      it "returns first static section given last static section" do
        expect(described_class.new(partner, "partner_settings").call).to eq("agency_information")
      end
    end
  end
end
