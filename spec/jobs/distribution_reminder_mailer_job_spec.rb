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

  describe "conditionally sending the emails" do
    let(:organization) { create :organization }

    let(:past_distribution) { create(:distribution, issued_at: Time.zone.now - 1.week) }
    let(:future_distribution) { create(:distribution, issued_at: Time.zone.now + 1.week) }

    let(:partner_with_no_reminders) { create :partner, send_reminders: false }
    let(:partner_with_reminders) { create :partner, send_reminders: true }
    let(:distribution_without_reminder) { create(:distribution, partner: partner_with_no_reminders) }
    let(:distribution_with_reminder) { create(:distribution, partner: partner_with_reminders) }

    it "does not send mail for past distributions" do
      Sidekiq::Testing.inline! do
        expect do
          DistributionReminderJob.perform_async(past_distribution.id)
        end.to_not change { ActionMailer::Base.deliveries.count }
      end
    end

    it "sends mail for future distributions" do
      Sidekiq::Testing.inline! do
        expect do
          DistributionReminderJob.perform_async(future_distribution.id)
        end.to change { ActionMailer::Base.deliveries.count }.by(1)
      end
    end

    it "does not send mail for future distributions if the partner wants no reminders" do
      Sidekiq::Testing.inline! do
        expect do
          DistributionReminderJob.perform_async(distribution_without_reminder.id)
        end.to_not change { ActionMailer::Base.deliveries.count }
      end
    end

    it "sends mail for future distributions where the partner wants reminders" do
      Sidekiq::Testing.inline! do
        expect do
          DistributionReminderJob.perform_async(distribution_with_reminder.id)
        end.to change { ActionMailer::Base.deliveries.count }.by(1)
      end
    end
  end
end
