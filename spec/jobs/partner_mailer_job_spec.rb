require 'spec_helper'

RSpec.describe PartnerMailerJob, type: :job do
  describe '#perform' do
    let(:organization) { create :organization }
    let(:distribution) { create :distribution }
    let(:mailer_subject) { 'PartnerMailerJob subject' }

    it 'adds job to the queue' do
      Sidekiq::Testing.fake! do
        expect do
          PartnerMailerJob.perform_async(organization.id, distribution.id, mailer_subject)
        end.to change(PartnerMailerJob.jobs, :size).by(1)
      end
    end

    it 'sends an email' do
      Sidekiq::Testing.inline! do
        expect do
          PartnerMailerJob.perform_async(organization.id, distribution.id, mailer_subject)
        end .to change { ActionMailer::Base.deliveries.count }.by(1)
      end
    end
  end

  describe "conditionally sending the emails" do
    let(:organization) { create :organization }
    let(:mailer_subject) { 'PartnerMailerJob subject' }
    let(:distribution) { create :distribution }

    let(:past_distribution) { create(:distribution, issued_at: Time.zone.now - 1.week) }
    let(:future_distribution) { create(:distribution, issued_at: Time.zone.now + 1.week) }

    it "does not send mail for past distributions" do
      Sidekiq::Testing.inline! do
        expect do
          PartnerMailerJob.perform_async(organization.id, past_distribution.id, mailer_subject)
        end.to_not change { ActionMailer::Base.deliveries.count }
      end
    end

    it "sends mail for future distributions" do
      Sidekiq::Testing.inline! do
        expect do
          PartnerMailerJob.perform_async(organization.id, distribution.id, mailer_subject)
        end.to change { ActionMailer::Base.deliveries.count }.by(1)
      end
    end
  end
end
