RSpec.describe RequestsConfirmationMailer, type: :mailer do
  let(:request) { create(:request) }
  let(:mail) { RequestsConfirmationMailer.confirmation_email(request) }

  let(:request_w_duplicates) { create(:request, :with_duplicates) }
  let(:mail_w_duplicates) { RequestsConfirmationMailer.confirmation_email(request_w_duplicates) }

  describe "#confirmation_email" do
    it 'renders the headers' do
      expect(mail.subject).to eq("#{request.organization.name} - Requests Confirmation")
      expect(mail.to).to eq([request.user_email])
      expect(mail.cc).to eq([request.partner.email])
      expect(mail.from).to include("no-reply@humanessentials.app")
    end

    it 'renders the body' do
      @organization.update!(email: "me@org.com")
      expect(mail.body.encoded).to match('This is an email confirmation')
      expect(mail.body.encoded).to match('For more info, please e-mail me@org.com')
    end
  end

  it 'handles duplicates' do
    @organization.update!(email: "me@org.com")
    expect(mail_w_duplicates.body.encoded).to match('This is an email confirmation')
    expect(mail_w_duplicates.body.encoded).to match(' - 100')
  end
end
