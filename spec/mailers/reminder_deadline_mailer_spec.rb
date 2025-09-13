RSpec.describe ReminderDeadlineMailer, type: :job do
  let(:organization) { create(:organization) }

  describe 'notify deadline' do
    let(:today) { Date.new(2022, 1, 10) }
    let(:partner) { create(:partner, organization: organization) }
    before(:each) do
      organization.reminder_email_text = "Custom reminder message"
      organization.update!(deadline_day: 1)
    end

    subject { described_class.notify_deadline(partner) }

    it 'renders the subject' do
      expect(subject.subject).to eq("#{organization.name} Deadline Reminder")
    end

    it 'renders the receiver email' do
      expect(subject.to).to contain_exactly(partner.email)
    end

    it 'renders the sender email' do
      expect(subject.from).to eq(["no-reply@humanessentials.app"])
    end

    it 'renders the body' do
      travel_to today do
        expect(subject.body.encoded)
          .to include("This is a friendly reminder that #{organization.name} requires your human essentials requests to " \
                       "be submitted by Tue, 01 Feb 2022")
      end
    end

    it 'renders the body with the reminder email text' do
      expect(subject.body.encoded).to include("Custom reminder message")
    end
  end
end
