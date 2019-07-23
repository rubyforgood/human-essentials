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
end
