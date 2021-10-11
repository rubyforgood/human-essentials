RSpec.describe DistributionCreateService, type: :service do
  include ActiveJob::TestHelper

  subject { DistributionCreateService }
  describe "call" do
    let!(:storage_location) { create(:storage_location, :with_items, item_count: 2) }
    let!(:distribution_params) { { organization_id: @organization.id, partner_id: @partner.id, storage_location_id: storage_location.id, delivery_method: :delivery, line_items_attributes: { "0": { item_id: storage_location.items.first.id, quantity: 5 } } } }

    it "creates a new distribution, adjusting storage location quantities" do
      expect do
        subject.new(distribution_params).call
      end.to change { storage_location.reload.size }.by(-5)
    end

    it "returns a successful object with Scheduled distribution" do
      result = subject.new(distribution_params).call
      expect(result).to be_instance_of(subject)
      expect(result).to be_success
      expect(result.distribution).to be_scheduled
    end

    context "partner has send reminders setting set to true" do
      it "Sends a PartnerMailer" do
        @partner.update!(send_reminders: true)

        expect do
          perform_enqueued_jobs only: PartnerMailerJob do
            subject.new(distribution_params).call
          end
        end.to change { ActionMailer::Base.deliveries.count }.by(1)
      end
    end

    context "partner has send reminders setting set to false" do
      it "does not send a PartnerMailer" do
        @partner.update!(send_reminders: false)

        expect(PartnerMailerJob).not_to receive(:perform_later)
        subject.new(distribution_params).call
      end
    end

    context "partner is deactivated" do
      it "does not send an email" do
        @partner.update!(send_reminders: true, status: "deactivated")

        expect do
          perform_enqueued_jobs only: PartnerMailerJob do
            subject.new(distribution_params).call
          end
        end.not_to change { ActionMailer::Base.deliveries.count }
      end
    end

    context "when provided with a request ID" do
      let!(:request) { create(:request) }

      it "changes the status of the request" do
        expect do
          subject.new(distribution_params, request.id).call
          request.reload
        end.to change { request.status }
      end

      context 'and the request already has a distribution associated with it' do
        let(:distribution) { create(:distribution) }
        before do
          request.update!(distribution_id: distribution.id)
        end

        it 'should not be successful' do
          result = subject.new(distribution_params, request.id).call
          expect(result.error.message).to eq("Request has already been fulfilled by Distribution #{distribution.id}")
          expect(result).not_to be_success
        end
      end
    end

    context "when there's not sufficient inventory" do
      let(:too_much_params) { { organization_id: @organization.id, partner_id: @partner.id, storage_location_id: storage_location.id, delivery_method: :delivery, line_items_attributes: { "0": { item_id: storage_location.items.first.id, quantity: 500 } } } }

      it "preserves the Insufficiency error and is unsuccessful" do
        result = subject.new(too_much_params).call
        expect(result.error).to be_instance_of(Errors::InsufficientAllotment)
        expect(result).not_to be_success
      end
    end

    context "when there's multiple line items and one has insufficient inventory" do
      let(:too_much_params) do
        {
          organization_id: @organization.id,
          partner_id: @partner.id,
          storage_location_id: storage_location.id,
          delivery_method: :delivery,
          line_items_attributes:
            {
              "0": { item_id: storage_location.items.first.id, quantity: 2 },
              "1": { item_id: storage_location.items.last.id, quantity: 500 }
            }
        }
      end

      it "preserves the Insufficiency error and is unsuccessful" do
        result = subject.new(too_much_params).call
        expect(result.error).to be_instance_of(Errors::InsufficientAllotment)
        expect(result).not_to be_success
      end
    end

    context "when it fails to save" do
      let(:bad_params) { { organization_id: @organization.id, storage_location_id: storage_location.id, line_items_attributes: { "0": { item_id: storage_location.items.first.id, quantity: 500 } } } }

      it "preserves the error and is unsuccessful" do
        result = subject.new(bad_params).call
        expect(result.error).to be_instance_of(ActiveRecord::RecordInvalid)
        expect(result).not_to be_success
      end
    end
  end
end
