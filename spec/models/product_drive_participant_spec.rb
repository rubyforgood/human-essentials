# == Schema Information
#
# Table name: product_drive_participants
#
#  id              :integer          not null, primary key
#  address         :string
#  business_name   :string
#  comment         :string
#  contact_name    :string
#  email           :string
#  latitude        :float
#  longitude       :float
#  phone           :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :integer
#

require "rails_helper"

RSpec.describe ProductDriveParticipant, type: :model do
  it_behaves_like "provideable"

  context "Validations" do
    it "is invalid unless it has either a phone number or an email" do
      expect(build(:product_drive_participant, phone: nil, email: nil)).not_to be_valid
      expect(build(:product_drive_participant, phone: nil)).to be_valid
      expect(build(:product_drive_participant, email: nil)).to be_valid
    end

    it "is invalid without an organization" do
      expect(build(:product_drive_participant, organization: nil)).not_to be_valid
    end
  end

  context "Methods" do
    describe "volume" do
      it "retrieves the amount of product that has been donated through this product drive" do
        dd = create(:product_drive)
        ddp = create(:product_drive_participant)
        create(:donation, :with_items, item_quantity: 10, source: Donation::SOURCES[:product_drive], product_drive: dd, product_drive_participant: ddp)
        expect(ddp.volume).to eq(10)
      end
    end

    describe "donation_source_view" do
      let!(:participant) { create(:product_drive_participant, contact_name: contact_name) }

      context "contact name present" do
        let(:contact_name) { "Contact Name" }

        it do
          expect(participant.donation_source_view).to eq("Contact Name (participant)")
        end
      end

      context "no contact name" do
        let(:contact_name) { nil }

        it do
          expect(participant.donation_source_view).to be_nil
        end
      end
    end
  end
end
