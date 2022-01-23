describe ReminderDeadlineMailer, type: :job, skip_seed: true do
  describe 'notify deadline' do
    let(:today) { Date.new(2022, 1, 10) }
    let(:organization) { create(:organization, skip_items: true, reminder_day: today.day) }
    let(:partner) { create(:partner, organization: organization) }
    let(:date) { Date.new(2022, 1, 1) }

    subject { described_class.notify_deadline(partner) }

    before do
      allow(DeadlineService).to receive(:new).with(partner: partner).and_return(OpenStruct.new(next_deadline: date))
    end

    it 'renders the subject' do
      expect(subject.subject).to eq("#{organization.name} Deadline Reminder")
    end

    it 'renders the receiver email' do
      expect(subject.to).to contain_exactly(partner.email)
    end

    it 'renders the sender email' do
      expect(subject.from).to eq(["info@humanessentials.app"])
    end

    it 'renders the body' do
      expect(subject.body)
        .to include("This is a friendly reminder that #{organization.name} requires your human essentials requests to "\
                     "be submitted by #{date.strftime("%a, %d %b %Y")}")
    end
  end
end
