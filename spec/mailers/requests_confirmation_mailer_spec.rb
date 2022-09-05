RSpec.describe RequestsConfirmationMailer, type: :mailer do
  let(:request) { create(:request) }

  describe "#confirmation_email" do
    let(:mail) { RequestsConfirmationMailer.confirmation_email(request) }

    it 'renders the headers' do
      expect(mail.subject).to eq("#{request.organization.name} - Requests Confirmation")
      expect(mail.to).to include(request.partner.email)
      expect(mail.from).to include("info@humanessentials.app")
    end

    it 'renders the body' do
      @organization.update!(email: "me@org.com")
      expect(mail.body.encoded).to match('This is an email confirmation')
      expect(mail.body.encoded).to match('For more info, please e-mail me@org.com')
    end
  end
end
