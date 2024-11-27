RSpec.describe RequestsConfirmationMailer, type: :mailer do
  let(:organization) { create(:organization, :with_items) }
  let(:request) { create(:request, organization: organization) }
  let(:mail) { RequestsConfirmationMailer.confirmation_email(request) }

  let(:request_w_varied_quantities) { create(:request, :with_varied_quantities, organization: organization) }
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

  it 'pairs the right quantities with the right item names' do
    organization.update!(email: "me@org.com")
    expect(mail_w_varied_quantities.body.encoded).to match('This is an email confirmation')
    request_w_varied_quantities.request_items.each { |ri|
      expected_string = "#{Item.find(ri["item_id"]).name} - #{ri["quantity"]}"
      expect(mail_w_varied_quantities.body.encoded).to include(expected_string)
    }
  end
  it "shows units" do
    Flipper.enable(:enable_packs)
    item1 = create(:item, organization:)
    item2 = create(:item, organization:)
    create(:item_unit, item: item1, name: "Pack")
    create(:item_unit, item: item2, name: "Pack")
    request_items = [
      {item_id: item1.id, quantity: 1, request_unit: "Pack"},
      {item_id: item2.id, quantity: 7, request_unit: "Pack"}
    ]
    request = create(:request, :pending, request_items:)
    email = RequestsConfirmationMailer.confirmation_email(request)
    expect(email.body.encoded).to match("1 Pack")
    expect(email.body.encoded).to match("7 Packs")
  end

  it "skips units when are not provided" do
    Flipper.enable(:enable_packs)
    item = create(:item, organization:)
    create(:item_unit, item: item, name: "Pack")
    request = create(:request, :pending, request_items: [{item_id: item.id, quantity: 7}])
    email = RequestsConfirmationMailer.confirmation_email(request)

    expect(email.body.encoded).not_to match("7 Packs")
  end
end
