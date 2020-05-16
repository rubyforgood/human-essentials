require 'spec_helper'

RSpec.describe DistributionReminder do
  describe "conditionally sending the emails" do
    let(:organization) { create :organization }

    let(:past_distribution) { create(:distribution, issued_at: Time.zone.now - 1.week) }
    let(:future_distribution) { create(:distribution, issued_at: Time.zone.now + 1.week) }

    let(:partner_with_no_reminders) { create :partner, send_reminders: false }
    let(:partner_with_reminders) { create :partner, send_reminders: true }
    let(:distribution_without_reminder) { create(:distribution, partner: partner_with_no_reminders) }
    let(:distribution_with_reminder) { create(:distribution, partner: partner_with_reminders) }

    context 'when the distribution_id does not match any Distribution' do
      it "does not send mail for non existent distributions" do
        DistributionReminder.perform(0)
        expect(DistributionMailer.method(:reminder_email)).not_to be_delayed
      end
    end

    it "does not send mail for past distributions" do
      DistributionReminder.perform(past_distribution.id)
      expect(DistributionMailer.method(:reminder_email)).not_to be_delayed(past_distribution)
    end

    it "sends mail for future distributions" do
      DistributionReminder.perform(future_distribution.id)
      expect(DistributionMailer.method(:reminder_email)).to be_delayed(future_distribution.id).until future_distribution.issued_at - 1.day
    end

    it "does not send mail for future distributions if the partner wants no reminders" do
      DistributionReminder.perform(distribution_without_reminder.id)
      expect(DistributionMailer.method(:reminder_email)).not_to be_delayed(distribution_without_reminder)
    end

    it "sends mail for future distributions where the partner wants reminders" do
      DistributionReminder.perform(distribution_with_reminder.id)
      expect(DistributionMailer.method(:reminder_email)).to be_delayed(distribution_with_reminder.id).until distribution_with_reminder.issued_at - 1.day
    end
  end
end

