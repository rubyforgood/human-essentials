describe ReminderDeadlineMailer, type: :job, skip_seed: true do
  describe 'notify deadline' do
    subject { described_class.notify_deadline(partner) }
    let(:partner) { create(:partner) }
    let(:organization) { partner.organization }

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
      deadline_date = "#{Date.current.year}-#{Date.current.month}-#{organization.deadline_day}".to_date.strftime('%a, %d %b %Y')
      expect(subject.body).to include("This is a friendly reminder that #{organization.name} requires your human essentials requests to be submitted by #{deadline_date}")
    end

    context "when the partner gets its deadline reminder data from a partner group association" do
      before do
        partner_group = create(:partner_group, deadline_day_of_month: organization.deadline_day - 1)
        partner_group.partners << partner
      end

      it 'renders the body with the partner group deadline day' do
        deadline_date = "#{Date.current.year}-#{Date.current.month}-#{partner.partner_group.deadline_day_of_month}".to_date.strftime('%a, %d %b %Y')
        expect(subject.body).to include("This is a friendly reminder that #{organization.name} requires your human essentials requests to be submitted by #{deadline_date}")
      end
    end
  end
end
