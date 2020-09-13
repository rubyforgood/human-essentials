RSpec.describe PartnerMailerJob, type: :job do
  describe "conditionally sending the emails" do
    let(:organization) { create :organization }
    let(:mailer_subject) { 'PartnerMailerJob subject' }
    let(:distribution) { create :distribution }

    let(:past_distribution) { create(:distribution, issued_at: Time.zone.now - 1.week) }
    let(:future_distribution) { create(:distribution, issued_at: Time.zone.now + 1.week) }

    it "does not send mail for past distributions" do
      expect do
        PartnerMailerJob.new.perform(organization.id, past_distribution.id, mailer_subject)
      end.not_to change { ActionMailer::Base.deliveries.count }
    end

    it "sends mail for future distributions immediately" do
      expect do
        PartnerMailerJob.new.perform(organization.id, future_distribution.id, mailer_subject)
      end.to change { ActionMailer::Base.deliveries.count }.by(1)
    end
  end
end
