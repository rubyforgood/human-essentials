require 'spec_helper'

RSpec.describe DistributionReminderJob, type: :job do
  describe '#perform' do
    let(:organization) { create :organization }
    let(:distribution) { create :distribution }

    it 'adds job to the queue' do
      Sidekiq::Testing.fake! do
        expect do
          DistributionReminderJob.perform_async(distribution.id)
        end.to change(DistributionReminderJob.jobs, :size).by(1)
      end
    end

    it 'sends an email' do
      Sidekiq::Testing.inline! do
        expect do
          DistributionReminderJob.perform_async(distribution.id)
        end .to change { ActionMailer::Base.deliveries.count }.by(1)
      end
    end
  end
end
