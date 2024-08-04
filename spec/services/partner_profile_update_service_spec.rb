RSpec.describe PartnerProfileUpdateService do
  let(:county_1) { create(:county, name: "county1", region: "region1") }
  let(:county_2) { create(:county, name: "county2", region: "region2") }

  let(:profile) { create(:partner_profile) }
  let!(:basic_correct_attributes) {
    {no_social_media_presence: true, served_areas_attributes: {"0": {county_id: county_1.id, client_share: 100}}}
  }
  let!(:basic_incorrect_attributes) { {no_social_media_presence: true, served_areas_attributes: {"0": {county_id: county_1.id, client_share: 98}}} }
  let(:other_incorrect_attributes) { {website: "", twitter: "", facebook: "", instagram: "", no_social_media_presence: false, served_areas_attributes: {"0": {county_id: county_1.id, client_share: 100}}} }
  let(:incorrect_attributes_missing_client_share) { {no_social_media_presence: true, served_areas_attributes: {"0": {county_id: county_1.id, client_share: nil}}} }
  let!(:partner_params) { {name: "a good name"} }

  describe "#call" do
    context "when there are no pre-existing served areas" do
      context "and the new values are correct" do
        it "stores the new values and returns success" do
          PartnerProfileUpdateService.new(profile.partner, partner_params, basic_correct_attributes).call
          expect(profile.served_areas.size).to eq(1)
          expect(profile.errors).to be_empty
        end

        context "and there are other errors in the profile" do
          it "does not store the new values and it returns a failure" do
            expect(profile.served_areas.size).to eq(0)
            result = PartnerProfileUpdateService.new(profile.partner, partner_params, other_incorrect_attributes).call
            expect(result.success?).to eq(false)
            expect(result.error.to_s).to include("No social media presence must be checked")
            profile.reload
            expect(profile.served_areas.size).to eq(0)
          end
        end
      end
      context "and the new values are incorrect" do
        it "does not store the new values and returns a failure" do
          expect(profile.served_areas.size).to eq(0)
          result = PartnerProfileUpdateService.new(profile.partner, partner_params, basic_incorrect_attributes).call
          expect(result.success?).to eq(false)
          expect(result.error.to_s).to include("Validation failed: Total client share must be 0 or 100")

          profile.reload
          expect(profile.served_areas.size).to eq(0)
        end
      end
    end
    context "when served area client shares pre-exist" do
      let!(:original_served_area_1) { create(:partners_served_area, partner_profile: profile, county: county_1, client_share: 51) }
      let!(:original_served_area_2) { create(:partners_served_area, partner_profile: profile, county: county_2, client_share: 49) }
      context "and the new values are correct" do
        context " and there are no other errors" do
          it "replaces the old values and returns success" do
            profile.reload
            result = PartnerProfileUpdateService.new(profile.partner, partner_params, basic_correct_attributes).call
            expect(result.success?).to eq(true)
            profile.reload
            expect(profile.served_areas.size).to eq(1)
            expect(profile.errors).to be_empty
          end
        end
        context "and there are errors on the profile" do
          it "maintains the old values and returns failure" do
            profile.reload
            expect(profile.served_areas.size).to eq(2)
            PartnerProfileUpdateService.new(profile.partner, partner_params, other_incorrect_attributes).call
            profile.reload
            expect(profile.served_areas.size).to eq(2)
            expect(profile.errors).to_not be_empty
          end
        end
      end

      context "and the new values are incorrect" do
        it "maintains the old values and returns failure" do
          profile.reload
          expect(profile.served_areas.size).to eq(2)
          result = PartnerProfileUpdateService.new(profile.partner, partner_params, basic_incorrect_attributes).call
          expect(result.success?).to eq(false)
          expect(result.error.to_s).to include("Validation failed: Total client share must be 0 or 100")
          profile.reload
          expect(profile.served_areas.size).to eq(2)
        end
      end

      context "and the new values include county but are missing client share" do
        it "maintains the old values and returns the correct validation error" do
          profile.reload
          expect(profile.served_areas.size).to eq(2)
          result = PartnerProfileUpdateService.new(profile.partner, partner_params, incorrect_attributes_missing_client_share).call
          expect(result.success?).to eq(false)
          expect(result.error.to_s).to include("Validation failed: Served areas client share is not a number, Served areas client share is not included in the list")
          profile.reload
          expect(profile.served_areas.size).to eq(2)
        end
      end
    end
  end
end
