RSpec.describe DistributionUpdateService, type: :service do
  subject { DistributionUpdateService }
  let(:storage_location) { create(:storage_location, :with_items) }
  let(:distribution) { FactoryBot.create(:distribution, :with_items, item_quantity: 10) }
  let(:new_attributes) { { line_items_attributes: { "0": { item_id: distribution.line_items.first.item_id, quantity: 2 } } } }

  describe "call" do
    it "replaces a big distribution with a smaller one, resulting in increased stored quantities" do
      expect do
        subject.new(distribution, new_attributes).call
      end.to change { distribution.storage_location.size }.by(8)
    end

    it "returns a successful object with the distribution" do
      result = subject.new(distribution, new_attributes).call
      expect(result).to be_instance_of(subject)
      expect(result).to be_success
      expect(result.distribution).to be_valid
    end

    describe "#resend_notification?" do
      it "evaluates to true if the issued at has changed" do
        result = subject.new(distribution, { issued_at: distribution.issued_at + 1.week })
        expect(result).to be_resend_notification
      end
    end

    context "when there's not sufficient inventory" do
      let(:too_much_params) do 
           { 
               organization_id: @organization.id, 
               partner_id: @partner.id, 
               storage_location_id: storage_location.id, 
               line_items_attributes: { 
                 .... 

      it "preserves the Insufficiency error and is unsuccessful" do
        result = subject.new(distribution, too_much_params).call
        expect(result.error).to be_instance_of(Errors::InsufficientAllotment)
        expect(result).not_to be_success
      end
    end

    context "when it fails to save" do
      let(:bad_params) { { organization_id: @organization.id, storage_location_id: 0 } }

      it "preserves the error and is unsuccessful" do
        result = subject.new(distribution, bad_params).call
        expect(result.error).to be_instance_of(ActiveRecord::RecordInvalid)
        expect(result).not_to be_success
      end
    end
  end
end
