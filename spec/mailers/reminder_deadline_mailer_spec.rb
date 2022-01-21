describe ReminderDeadlineMailer, type: :job, skip_seed: true do
  describe 'notify deadline' do
    let(:today) { Date.new(2022, 1, 10) }
    let(:organization) { create(:organization, skip_items: true, reminder_day: today.day) }
    let(:partner) { create(:partner, organization: organization) }

    around do |example|
      travel_to(today) { example.run }
    end

    subject { described_class.notify_deadline(partner) }

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
      deadline_date = today.change(day: organization.deadline_day).strftime('%a, %d %b %Y')

      expect(subject.body).to include("This is a friendly reminder that #{organization.name} requires your human essentials requests to be submitted by #{deadline_date}")
    end

    context 'when the reminder day is greater than the deadline day' do
      before { organization.update(deadline_day: today.prev_day.day) }

      it 'specifies the deadline as being in the next month' do
        deadline_date = today.next_month.change(day: organization.deadline_day).strftime('%a, %d %b %Y')

        expect(subject.body).to include("This is a friendly reminder that #{organization.name} requires your human essentials requests to be submitted by #{deadline_date}")
      end
    end

    context "when the partner gets its deadline reminder data from a partner group association" do
      before do
        partner_group = create(:partner_group, reminder_day_of_month: today.day, deadline_day_of_month: organization.deadline_day - 1)
        partner_group.partners << partner
      end

      it 'renders the body with the partner group deadline day' do
        deadline_date = today.change(day: partner.partner_group.deadline_day_of_month).strftime('%a, %d %b %Y')

        expect(subject.body).to include("This is a friendly reminder that #{organization.name} requires your human essentials requests to be submitted by #{deadline_date}")
      end
    end
  end
end
