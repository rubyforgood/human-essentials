RSpec.describe ReminderDeadlineJob, type: :job do
  let(:todays_day) { 10 }
  let(:not_today) { 11 }
  let(:deadline_day) { 20 }

  describe '#perform' do
    let(:complete_organization) { create :organization, reminder_day: todays_day, deadline_day: deadline_day }

    before do
      Organization.destroy_all
      Partner.destroy_all
      travel_to Date.new(2019, 6, todays_day)
    end

    after do
      travel_back
    end

    context 'partner with send reminders active, a reminder day set to today, and a deadline day set' do
      let!(:partner) { create :partner, organization: complete_organization, send_reminders: true }

      it "sends Reminder deadline e-mail to the organization's partner" do
        with_features reminders_active: true do
          expect do
            ReminderDeadlineJob.perform_now
          end.to change { ActionMailer::Base.deliveries.count }.by(1)
        end
      end
    end

    context 'partner inactivated send reminders' do
      let(:partner) { create :partner, organization: complete_organization, send_reminders: false }

      it 'does not send the notify deadline e-mail' do
        with_features reminders_active: true do
          expect(ReminderDeadlineMailer).not_to receive(:notify_deadline)
          expect do
            ReminderDeadlineJob.perform_now
          end.not_to change { ActionMailer::Base.deliveries.count }
        end
      end
    end

    context 'deactivated partner with send reminders active' do
      let!(:partner) { create :partner, organization: complete_organization, send_reminders: true, status: 'deactivated' }

      it 'does not send the notify deadline e-mail' do
        with_features reminders_active: true do
          expect do
            ReminderDeadlineJob.perform_now
          end.not_to change { ActionMailer::Base.deliveries.count }
        end
      end
    end

    context 'organization without deadline dates' do
      let(:incomplete_organization) { create :organization, reminder_day: todays_day, deadline_day: nil }
      let(:partner) { create :partner, organization: incomplete_organization }

      it 'does not send the notify deadline email' do
        with_features reminders_active: true do
          expect(ReminderDeadlineMailer).not_to receive(:notify_deadline)
          expect do
            ReminderDeadlineJob.perform_now
          end.not_to change { ActionMailer::Base.deliveries.count }
        end
      end
    end

    context 'organization with deadline dates, but no reminder day' do
      let(:incomplete_organization) { create :organization, reminder_day: nil, deadline_day: deadline_day }
      let(:partner) { create :partner, organization: incomplete_organization }

      it 'does not send the notify deadline email' do
        with_features reminders_active: true do
          expect(ReminderDeadlineMailer).not_to receive(:notify_deadline)
          expect do
            ReminderDeadlineJob.perform_now
          end.not_to change { ActionMailer::Base.deliveries.count }
        end
      end
    end

    context 'organization with a reminder and deadline date set, but when today is not the reminder day' do
      let(:indifferent_organization) { create :organization, reminder_day: not_today, deadline_day: deadline_day }
      let(:partner) { create :partner, organization: indifferent_organization }

      it 'does not send the notify deadline email' do
        with_features reminders_active: true do
          expect(ReminderDeadlineMailer).not_to receive(:notify_deadline)
          expect do
            ReminderDeadlineJob.perform_now
          end.not_to change { ActionMailer::Base.deliveries.count }
        end
      end
    end
  end
end
