RSpec.describe DistributionCreateService, type: :service do
  let(:organization) { create(:organization) }
  let(:partner) { create(:partner, organization: organization) }

  include ActiveJob::TestHelper

  subject { DistributionCreateService }
  describe "call" do
    let!(:storage_location) { create(:storage_location, :with_items, item_count: 2, organization: organization) }
    let!(:distribution) {
      Distribution.new(organization_id: organization.id,
        partner_id: partner.id,
        storage_location_id: storage_location.id,
        delivery_method: :delivery,
        line_items_attributes: {
          "0": { item_id: storage_location.items.first.id, quantity: 5 }
        })
    }

    it "replaces a big distribution with a smaller one, resulting in increased stored quantities" do
      expect do
        subject.new(distribution).call
      end.to change { storage_location.reload.size }.by(-5)
        .and change { DistributionEvent.count }.by(1)
    end

    it "returns a successful object with Scheduled distribution" do
      result = subject.new(distribution).call
      expect(result).to be_instance_of(subject)
      expect(result).to be_success
      expect(result.distribution).to be_scheduled
    end

    context "partner has send reminders setting set to true" do
      it "Sends a PartnerMailer" do
        partner.update!(send_reminders: true)

        expect do
          perform_enqueued_jobs only: PartnerMailerJob do
            subject.new(distribution).call
          end
        end.to change { ActionMailer::Base.deliveries.count }.by(1)
      end
    end

    context "partner has send reminders setting set to false" do
      it "does not send a PartnerMailer" do
        partner.update!(send_reminders: false)

        expect(PartnerMailerJob).not_to receive(:perform_later)
        subject.new(distribution).call
      end
    end

    context "partner is deactivated" do
      it "does not send an email" do
        partner.update!(send_reminders: true, status: "deactivated")

        expect do
          perform_enqueued_jobs only: PartnerMailerJob do
            subject.new(distribution).call
          end
        end.not_to change { ActionMailer::Base.deliveries.count }
      end
    end

    context "when provided with a request ID" do
      let!(:request) { create(:request, organization: organization) }

      it "changes the status of the request" do
        expect do
          subject.new(distribution, request.id).call
          request.reload
        end.to change { request.status }
      end

      context 'and the request already has a distribution associated with it' do
        let(:distribution) { create(:distribution, organization: organization) }
        before do
          request.update!(distribution_id: distribution.id)
        end

        it 'should not be successful' do
          result = subject.new(distribution, request.id).call
          expect(result.error.message).to eq("Request has already been fulfilled by Distribution #{distribution.id}")
          expect(result).not_to be_success
        end
      end
    end

    context "when there's not sufficient inventory" do
      let(:too_much_dist) {
        Distribution.new(
          organization_id: organization.id,
          partner_id: partner.id,
          storage_location_id: storage_location.id,
          delivery_method: :delivery,
          line_items_attributes: { "0": { item_id: storage_location.items.first.id, quantity: 500 } }
        )
      }

      it "preserves the Insufficiency error and is unsuccessful" do
        result = subject.new(too_much_dist).call
        error_class = Event.read_events?(organization) ? InventoryError : Errors::InsufficientAllotment
        expect(result.error).to be_instance_of(error_class)
        expect(result).not_to be_success
      end
    end

    context "when there's multiple line items and one has insufficient inventory" do
      let(:too_much_dist) do
        Distribution.new(
          organization_id: organization.id,
          partner_id: partner.id,
          storage_location_id: storage_location.id,
          delivery_method: :delivery,
          line_items_attributes:
            {
              "0": { item_id: storage_location.items.first.id, quantity: 2 },
              "1": { item_id: storage_location.items.last.id, quantity: 500 }
            }
        )
      end

      it "preserves the Insufficiency error and is unsuccessful" do
        result = subject.new(too_much_dist).call
        error_class = Event.read_events?(organization) ? InventoryError : Errors::InsufficientAllotment
        expect(result.error).to be_instance_of(error_class)
        expect(result).not_to be_success
      end
    end

    context "when it fails to save" do
      let(:bad_dist) {
        Distribution.new(organization_id: organization.id,
          storage_location_id: storage_location.id,
          line_items_attributes: {
            "0": { item_id: storage_location.items.first.id, quantity: 500 }
          })
      }

      it "preserves the error and is unsuccessful" do
        result = subject.new(bad_dist).call
        expect(result.error).to be_instance_of(ActiveRecord::RecordInvalid)
        expect(result).not_to be_success
      end
    end

    context "when the line item quantity is not positive" do
      let(:dist) {
        Distribution.new(
          organization_id: organization.id,
          partner_id: partner.id,
          storage_location_id: storage_location.id,
          delivery_method: :delivery,
          line_items_attributes: { "0": { item_id: storage_location.items.first.id, quantity: 0 } }
        )
      }

      it "preserves the RecordInvalid error and is unsuccessful" do
        result = subject.new(dist).call
        expect(result.error).to be_instance_of(ActiveRecord::RecordInvalid)
        expect(result).not_to be_success
      end
    end
  end
end
