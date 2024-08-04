RSpec.describe OrganizationUpdateService do
  let(:organization) { create(:organization) }

  describe "#update" do
    context "when object is valid" do
      it "should update and return true" do
        params = {name: "A brand NEW NEW name"}
        described_class.update(organization, params)
        expect(organization.errors.none?).to eq(true)
        expect(organization.reload.name).to eq("A brand NEW NEW name")
      end

      it "Should set request_units on the organization" do
        Flipper.enable(:enable_packs)
        params = {request_unit_names: ["newpack"]}
        described_class.update(organization, params)
        expect(organization.errors.none?).to eq(true)
        expect(organization.reload.request_units.pluck(:name)).to match_array(["newpack"])
      end
    end

    context "when object is invalid" do
      it "should not update and return false" do
        params = {name: "A brand NEW NEW name",
                  url: "something that IS NOT A URL"}
        described_class.update(organization, params)
        expect(organization.errors.any?).to eq(true)
        expect(organization.reload.name).not_to eq("A brand NEW NEW name")
      end
    end

    context "when organization has partners" do
      let(:organization) do
        create(:organization, enable_individual_requests: true, enable_child_based_requests: true, enable_quantity_based_requests: true)
      end
      let(:partners) { create_list(:partner, 2, organization: organization) }
      let(:partner_one) { partners.first }
      let(:partner_two) { partners.last }

      before do
        partner_one.profile.update!(
          enable_individual_requests: true,
          enable_child_based_requests: true,
          enable_quantity_based_requests: false
        )
        partner_two.profile.update!(
          enable_individual_requests: true,
          enable_child_based_requests: true,
          enable_quantity_based_requests: true
        )
      end

      context "when all of a single partner's request flags will be disabled" do
        before { described_class.update(organization, {enable_individual_requests: false, enable_child_based_requests: false}) }

        it "should NOT change request flags in organization or its partners" do
          organization.reload
          partner_one.profile.reload
          partner_two.profile.reload

          aggregate_failures "request type in organization and partners" do
            expect(organization.enable_individual_requests).to eq(true)
            expect(partner_one.profile.enable_individual_requests).to eq(true)
            expect(partner_two.profile.enable_individual_requests).to eq(true)
            expect(organization.enable_child_based_requests).to eq(true)
            expect(partner_one.profile.enable_child_based_requests).to eq(true)
            expect(partner_two.profile.enable_child_based_requests).to eq(true)
          end
        end

        it "should add an error message to the organization" do
          expect(organization.errors.full_messages).to eq(["The following partners would be unable to make requests with this update: #{partner_one.name}"])
        end
      end

      context "when all of a single partner's request flags WILL NOT be disabled" do
        before { described_class.update(organization, enable_individual_requests: "false") }

        it "should allow the disabling of request flags in organization and its partners" do
          organization.reload
          partner_one.profile.reload
          partner_two.profile.reload

          aggregate_failures "request type in organization and partners" do
            expect(organization.enable_individual_requests).to eq(false)
            expect(partner_one.profile.enable_individual_requests).to eq(false)
            expect(partner_two.profile.enable_individual_requests).to eq(false)
          end
        end
      end
    end
  end

  describe "#update_partner_flags" do
    before(:each) do
      partners = create_list(:partner, 2, organization: organization)
      partners.each { |p|
        p.profile.update!(
          enable_individual_requests: true,
          enable_child_based_requests: true,
          enable_quantity_based_requests: true
        )
      }
    end

    context "when request flags haven't changed" do
      it "should not update partners" do
        described_class.update_partner_flags(organization)
        expect(organization.partners.map { |p| p.profile.enable_child_based_requests })
          .to eq([true, true])
        expect(organization.partners.map { |p| p.profile.enable_individual_requests })
          .to eq([true, true])
        expect(organization.partners.map { |p| p.profile.enable_quantity_based_requests })
          .to eq([true, true])
      end
    end

    context "when request flags have changed" do
      it "should update partners when disabling child and individual request flags" do
        organization.update!(enable_child_based_requests: false, enable_individual_requests: false, enable_quantity_based_requests: true)
        described_class.update_partner_flags(organization)
        expect(organization.partners.map { |p| p.profile.enable_child_based_requests })
          .to eq([false, false])
        expect(organization.partners.map { |p| p.profile.enable_individual_requests })
          .to eq([false, false])
        expect(organization.partners.map { |p| p.profile.enable_quantity_based_requests })
          .to eq([true, true])
      end

      it "should update partners when disabling quantity-based request flags" do
        organization.update!(enable_quantity_based_requests: false)
        described_class.update_partner_flags(organization)
        expect(organization.partners.map { |p| p.profile.enable_child_based_requests })
          .to eq([true, true])
        expect(organization.partners.map { |p| p.profile.enable_individual_requests })
          .to eq([true, true])
        expect(organization.partners.map { |p| p.profile.enable_quantity_based_requests })
          .to eq([false, false])
      end

      it "should NOT update partners' request flags when enabling request flags on the organization" do
        organization.partners.each { |p|
          p.profile.update!(
            enable_individual_requests: true,
            enable_child_based_requests: false,
            enable_quantity_based_requests: false
          )
        }

        described_class.update_partner_flags(organization)

        expect(organization.partners.map { |p| p.profile.enable_child_based_requests })
          .to eq([false, false])
        expect(organization.partners.map { |p| p.profile.enable_individual_requests })
          .to eq([true, true])
        expect(organization.partners.map { |p| p.profile.enable_quantity_based_requests })
          .to eq([false, false])
      end
    end
  end
end
