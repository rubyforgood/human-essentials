RSpec.describe RequestsConfirmationMailer, type: :mailer do
  let(:request) { create(:request) }

  describe "#confirmation_email" do
    let(:mail) { RequestsConfirmationMailer.confirmation_email(request) }

    it 'renders the headers' do
      expect(mail.subject).to eq("#{request.organization.name} - Requests Confirmation")
      expect(mail.to).to include(request.partner.email)
      expect(mail.from).to include(request.organization.email)
    end

    it 'renders the body' do
      expect(mail.body.encoded).to match('This is an email confirmation')
    end
  end
end
