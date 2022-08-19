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

  describe "sync_visible_partner_form_sections" do
    subject do
      described_class.sync_visible_partner_form_sections(organization)
    end

    context "when partner_form_fields have not changed" do
      before do
        expect(Partners::PartnerForm.where(essentials_bank_id: organization.id).count).to eq(0)
      end

      it "should not make any changes" do
        expect { subject }.not_to change {
          Partners::PartnerForm.where(essentials_bank_id: organization.id).count
        }
      end
    end

    context "when the partner_form_fields change" do
      let(:partner_fields) { Organization::ALL_PARTIALS.map { |t| t[0] }.sample(3) }
      before do
        organization.partner_form_fields = partner_fields
        organization.save!
      end

      context "and a Partners::PartnerForm does not exist yet" do
        before do
          expect(Partners::PartnerForm.where(essentials_bank_id: organization.id).count).to eq(0)
        end

        it "should create or update the new partner form with the correct section values" do
          expect { subject }.to change {
            Partners::PartnerForm.where(essentials_bank_id: organization.id, sections: organization.partner_form_fields).count
          }.by(1)
        end
      end

      context "and a Partners::PartnerForm already exists" do
        let!(:existing_partner_form) { Partners::PartnerForm.new(essentials_bank_id: organization.id, sections: []).tap(&:save!) }

        it "should update the existing partner form" do
          expect { subject }.to change {
            existing_partner_form.reload.sections
          }.to(partner_fields)
        end
      end
    end
  end
end
