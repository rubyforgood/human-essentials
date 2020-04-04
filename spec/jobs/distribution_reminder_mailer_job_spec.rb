require 'spec_helper'

RSpec.describe DistributionReminderJob, type: :job do
  describe '#perform' do
    let(:organization) { create :organization }
    let(:distribution) { create :distribution }

    it 'sends an email' do
      Sidekiq::Testing.inline! do
        expect do
          DistributionReminderJob.perform_later(distribution.id)
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
      DistributionReminderJob.perform_now(past_distribution.id)
      expect(DistributionMailer.method :reminder_email).not_to be_delayed(past_distribution)
    end

    it "sends mail for future distributions" do
      DistributionReminderJob.perform_now(future_distribution.id)
      expect(DistributionMailer.method :reminder_email).to be_delayed(future_distribution).until future_distribution.issued_at - 1.day 
    end

    it "does not send mail for future distributions if the partner wants no reminders" do
      DistributionReminderJob.perform_now(distribution_without_reminder.id)
      expect(DistributionMailer.method :reminder_email).not_to be_delayed(distribution_without_reminder)
    end

    it "sends mail for future distributions where the partner wants reminders" do
      DistributionReminderJob.perform_now(distribution_with_reminder.id)
      expect(DistributionMailer.method :reminder_email).to be_delayed(distribution_with_reminder).until distribution_with_reminder.issued_at - 1.day       
    end
  end
end
