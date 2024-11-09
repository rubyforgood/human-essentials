require "rails_helper"

RSpec.describe Partners::SectionErrorService, type: :service do
  describe ".sections_with_errors" do
    subject { Partners::SectionErrorService.sections_with_errors(error_keys) }

    context "when error keys map to multiple sections" do
      let(:error_keys) { [:website, :pick_up_email, :enable_quantity_based_requests] }

      it "returns an array with each section containing an error" do
        expect(subject).to contain_exactly("media_information", "pick_up_person", "partner_settings")
      end
    end

    context "when error keys map to the same section multiple times" do
      let(:error_keys) { [:website, :twitter, :facebook] }

      it "returns a unique array with only one instance of the section" do
        expect(subject).to eq(["media_information"])
      end
    end

    context "when error keys include fields not mapped to any section" do
      let(:error_keys) { [:website, :unknown_field, :enable_quantity_based_requests] }

      it "excludes nil values for unmapped fields and returns unique sections" do
        expect(subject).to eq(["media_information", "partner_settings"])
      end
    end

    context "when none of the error keys match any section" do
      let(:error_keys) { [:unknown_field_1, :unknown_field_2] }

      it "returns an empty array when no sections match" do
        expect(subject).to be_empty
      end
    end

    context "when error keys are empty" do
      let(:error_keys) { [] }

      it "returns an empty array" do
        expect(subject).to eq([])
      end
    end
  end
end
