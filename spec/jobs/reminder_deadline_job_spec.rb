RSpec.describe ReminderDeadlineJob, type: :job do
  describe '#perform' do
    subject { -> { described_class.perform_now } }
    let(:partner) { create(:partner) }
    let(:fake_mailer_job) { double('mailer', deliver_later: -> {}) }

    before do
      allow_any_instance_of(Partners::FetchPartnersToRemindNowService).to receive(:fetch).and_return([partner])
      allow(ReminderDeadlineMailer).to receive(:notify_deadline).with(partner).and_return(fake_mailer_job)
    end

    it 'should queue up reminder deadline emails for all partners that should be reminded' do
      subject.call
      expect(fake_mailer_job).to have_received(:deliver_later)
    end
  end
end
