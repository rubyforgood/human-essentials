require 'spec_helper'

RSpec.describe ReminderDeadlineJob, type: :job do
  describe '#perform' do
    let(:organization) { create :organization, reminder_day: Date.current.day, deadline_day: Date.current.day + 10 }

    before do
      travel_to Date.new(2019, 6, 10)
    end

    after do
      travel_back
    end

    it 'adds job to the queue' do
      Sidekiq::Testing.fake! do
        expect do
          ReminderDeadlineJob.perform_async
        end.to change(ReminderDeadlineJob.jobs, :size).by(1)
      end
    end

    it 'sends an email' do
      Sidekiq::Testing.inline! do
        expect do
          ReminderDeadlineJob.perform_async
        end .to change { ActionMailer::Base.deliveries.count }.by(1)
      end
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
