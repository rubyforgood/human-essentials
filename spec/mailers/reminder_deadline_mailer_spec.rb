require 'spec_helper'

describe ReminderDeadlineMailer do
  describe 'notify deadline' do
    let(:organization) { create :organization }
    let(:partner) { create :partner, organization: organization }
    let(:mail) { ReminderDeadlineMailer.notify_deadline(partner, organization) }

    it 'renders the subject' do
      expect(mail.subject).to eq("#{organization.name} Deadline Reminder")
    end

    it 'renders the receiver email' do
      expect(mail.to).to contain_exactly(partner.email)
    end

    it 'renders the sender email' do
      expect(mail.from).to contain_exactly('info@diaper.app')
    end

    it 'renders the body' do
      expect(mail.body).to include(organization.deadline_day)
    end
  end
end