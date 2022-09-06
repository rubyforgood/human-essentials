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
        expect do
          DistributionReminder.perform(0)
        end.not_to have_enqueued_job(ActionMailer::MailDeliveryJob).with('DistributionMailer', 'reminder_email', 'deliver_now')
      end
    end

    it "does not send mail for past distributions" do
      expect do
        DistributionReminder.perform(past_distribution.id)
      end.not_to have_enqueued_job(ActionMailer::MailDeliveryJob).with('DistributionMailer', 'reminder_email', 'deliver_now')
    end

    it "sends mail for future distributions" do
      expect do
        DistributionReminder.perform(future_distribution.id)
      end.to have_enqueued_job(ActionMailer::MailDeliveryJob).with('DistributionMailer', 'reminder_email', 'deliver_now', args: [future_distribution.id])
    end

    it "does not send mail for future distributions if the partner wants no reminders" do
      expect do
        DistributionReminder.perform(distribution_without_reminder.id)
      end.not_to have_enqueued_job(ActionMailer::MailDeliveryJob).with('DistributionMailer', 'reminder_email', 'deliver_now')
    end

    it "sends mail for future distributions where the partner wants reminders" do
      expect do
        DistributionReminder.perform(distribution_with_reminder.id)
      end.to have_enqueued_job(ActionMailer::MailDeliveryJob).with('DistributionMailer', 'reminder_email', 'deliver_now', args: [distribution_with_reminder.id])
    end

    context "when the partner is deactivated" do
      let(:deactivated_partner) { create(:partner, send_reminders: true, status: "deactivated") }
      let(:distribution) { create(:distribution, partner: deactivated_partner) }

      it "does not send mail" do
        expect do
          DistributionReminder.perform(distribution.id)
        end.not_to have_enqueued_job(ActionMailer::MailDeliveryJob).with('DistributionMailer', 'reminder_email', 'deliver_now')
      end
    end
  end
end
