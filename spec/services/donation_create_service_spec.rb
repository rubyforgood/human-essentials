RSpec.describe DonationCreateService do
  describe "#call" do
    let(:donation) { FactoryBot.build(:donation) }

    it "should create the donation" do
      expect { described_class.call(donation) }
        .to change { Donation.count }.by(1)
        .and change { DonationEvent.count }.by(1)
    end

    context "when missing issued_at attribute" do
      before { donation.issued_at = "" }

      it "raises a validation error" do
        expect { described_class.call(donation) }.to raise_error("Issue date can't be blank")
      end
    end
  end
end
