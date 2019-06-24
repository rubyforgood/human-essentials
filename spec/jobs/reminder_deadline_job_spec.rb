require 'spec_helper'

RSpec.describe ReminderDeadlineJob, type: :job do
  describe '#perform' do
    let(:organization) { create :organization, reminder_day: Date.current.day, deadline_day: Date.current.day + 10 }
    let(:message_delivery) { instance_double(ActionMailer::MessageDelivery) }

    before do
      travel_to Date.new(2019, 6, 10)
      allow(ReminderDeadlineMailer).to receive(:notify_deadline).and_return(message_delivery)
      allow(message_delivery).to receive(:deliver_now)
    end

    after do
      travel_back
    end

    context 'partner with send reminders active' do
      let(:partner) { create :partner, organization: organization }

      it 'executes perform' do
        Sidekiq::Testing.inline! do
          expect do
            expect(ReminderDeadlineMailer).to receive(:notify_deadline).with(partner, organization)
            ReminderDeadlineJob.perform_async
          end
        end
      end
    end

    context 'partner without send reminders active' do
      let(:partner) { create :partner, organization: organization, send_reminders: false }

      it 'executes perform' do
        Sidekiq::Testing.inline! do
          expect do
            expect(ReminderDeadlineMailer).not_to receive(:notify_deadline)
            ReminderDeadlineJob.perform_async
          end
        end
      end
    end

    context 'organization without reminder and deadline dates' do
      let(:organization) { create :organization, reminder_day: nil, deadline_day: nil }
      let(:partner) { create :partner, organization: organization }

      it 'executes perform' do
        Sidekiq::Testing.inline! do
          expect do
            expect(ReminderDeadlineMailer).not_to receive(:notify_deadline)
            ReminderDeadlineJob.perform_async
          end
        end
      end
    end

    context 'organization with 11 as reminder date' do
      let(:organization) { create :organization, reminder_day: 11, deadline_day: 21 }
      let(:partner) { create :partner, organization: organization }

      it 'executes perform' do
        Sidekiq::Testing.inline! do
          expect do
            expect(ReminderDeadlineMailer).not_to receive(:notify_deadline)
            ReminderDeadlineJob.perform_async
          end
        end
      end
    end
  end
end