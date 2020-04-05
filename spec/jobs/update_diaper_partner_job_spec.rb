RSpec.describe UpdateDiaperPartnerJob, job: true do
  describe '#perform(partner_id)' do
    subject { described_class.new.perform(partner_id) }
    let(:partner_id) { Faker::Number.number }

    context 'when the email feature is active' do
      let(:fake_partner) { instance_double(Partner, attributes: { fake: 'data' }) }

      before do
        # Force email to be enabled
        allow(Flipper).to receive(:enabled?).with(:email_active).and_return(true)

        allow(Partner).to receive(:find).with(partner_id).and_return(fake_partner)

        # Pre-program all interactions with the fake partner. This is to
        # remove any dependencies on what Partner actually does.
        fake_invitation_text = Faker::Lorem.sentences
        fake_organization_email = Faker::Internet.email

        allow(fake_partner).to receive_message_chain(:organization, :invitation_text).and_return(fake_invitation_text)
        allow(fake_partner).to receive_message_chain(:organization, :email).and_return(fake_organization_email)

        # The below will fail the test if `.with(...)` doesn't
        # match what is actually happening.
        allow(DiaperPartnerClient).to receive(:post)
          .with(fake_partner.attributes.merge({ organization_email: fake_organization_email }), fake_invitation_text)
          .and_return({})

        allow(fake_partner).to receive(:invited!)
      end

      it 'should have called invited! on the partner' do
        subject
        expect(fake_partner).to have_received(:invited!)
      end
    end
  end

  describe "Responses >" do
    context "with a successful POST response" do
      before do
        @partner = create(:partner)
        response = double("Response", value: Net::HTTPSuccess)
        allow(DiaperPartnerClient).to receive(:post).and_return(response)
      end

      it "checks the partner status is default set to pending" do
        with_features email_active: true do
          Sidekiq::Testing.inline! do
            expect do
              UpdateDiaperPartnerJob.perform_async(@partner.id)
              @partner.reload
            end
            expect(@partner.status).to eq("uninvited")
          end
        end
      end
    end

    context "with a unsuccessful POST response" do
      before do
        @partner = create(:partner)
        response = double("Response", value: nil)
        allow(DiaperPartnerClient).to receive(:post).and_return(response)
      end

      it "sets the partner status to error" do
        pending
        with_features email_active: true do
          Sidekiq::Testing.inline! do
            expect do
              UpdateDiaperPartnerJob.perform_async(@partner.id)
              @partner.reload
            end.to change { @partner.status }.to("error")
          end
        end
      end

      it "posts via DiaperPartnerClient" do
        with_features email_active: true do
          Sidekiq::Testing.inline! do
            partner = create(:partner)
            allow(Flipper).to receive(:enabled?) { true }

            expect(DiaperPartnerClient).to receive(:post)

            UpdateDiaperPartnerJob.perform_async(partner.id)
          end
        end
      end
    end
  end
end
