RSpec.describe AddDiaperPartnerJob, job: true do
  describe "#perform" do
    let(:partner) do
      partner = create(:partner)
      partner.organization.update!(invitation_text: 'Invitation')
      partner
    end

    context "successful diaper client request" do
      before do
        response = double("Response", value: Net::HTTPSuccess)
        allow(DiaperPartnerClient).to receive(:add).and_return(response)
      end

      it "invokes add method on diaper partner client with proper arguments" do
        Sidekiq::Testing.inline! do
          AddDiaperPartnerJob.perform_async(partner.id, email: 'test@test.com')

          expect(DiaperPartnerClient).to have_received(:add) do |partner_data, invitation_text|
            expect(invitation_text).to eq 'Invitation'
            expect(partner_data).to include('email' => 'test@test.com',
                                            'name' => partner.name,
                                            'organization_id' => partner.organization_id,
                                            'status' => partner.status,
                                            'send_reminders' => partner.send_reminders)
          end
        end
      end
    end
  end
end
