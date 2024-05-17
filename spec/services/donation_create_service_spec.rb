RSpec.describe DonationCreateService do
  describe "#call" do
    let(:donation) { FactoryBot.build(:donation) }

    it "should create the donation" do
      expect { described_class.call(donation) }
        .to change { Donation.count }.by(1)
        .and change { DonationEvent.count }.by(1)
    end
  end
end
