RSpec.describe RequestsConfirmationMailer, type: :mailer do
  let(:organization) { create(:organization, :with_items) }
  let(:request) { create(:request, organization: organization) }
  let(:mail) { RequestsConfirmationMailer.confirmation_email(request) }

  let(:request_w_duplicates) { create(:request, :with_duplicates, organization: organization) }
  let(:request_w_varied_quantities) { create(:request, :with_varied_quantities, organization: organization) }
  let(:mail_w_duplicates) { RequestsConfirmationMailer.confirmation_email(request_w_duplicates) }
  let(:mail_w_varied_quantities) { RequestsConfirmationMailer.confirmation_email(request_w_varied_quantities) }

  describe "#confirmation_email" do
    it 'renders the headers' do
      expect(mail.subject).to eq("#{request.organization.name} - Requests Confirmation")
      expect(mail.to).to eq([request.user_email])
      expect(mail.cc).to eq([request.partner.email])
      expect(mail.from).to include("no-reply@humanessentials.app")
    end

    it 'renders the body' do
      organization.update!(email: "me@org.com")
      expect(mail.body.encoded).to match('This is an email confirmation')
      expect(mail.body.encoded).to match('For more info, please e-mail me@org.com')
    end
  end

  it 'handles duplicates' do
    organization.update!(email: "me@org.com")
    expect(mail_w_duplicates.body.encoded).to match('This is an email confirmation')
    expect(mail_w_duplicates.body.encoded).to match(' - 100')
  end

  it 'pairs the right quantities with the right item names' do
    organization.update!(email: "me@org.com")
    expect(mail_w_varied_quantities.body.encoded).to match('This is an email confirmation')
    request_w_varied_quantities.request_items.each { |ri|
      expected_string = "#{Item.find(ri["item_id"]).name} - #{ri["quantity"]}"
      expect(mail_w_varied_quantities.body.encoded).to include(expected_string)
    }
  end
end
