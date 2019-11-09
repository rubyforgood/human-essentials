RSpec.describe DistributionMailer, type: :mailer do
  before do
    @organization.default_email_text = "Default email text example"
    @distribution = create(:distribution, organization: @user.organization, comment: "Distribution comment")
  end

  let(:mail) { DistributionMailer.partner_mailer(@organization, @distribution, 'test subject') }

  it "renders the body with organizations email text" do
    expect(mail.body.encoded).to match("Default email text example")
    expect(mail.subject).to eq("test subject from DEFAULT")
  end

  it "renders the body with distributions text" do
    expect(mail.body.encoded).to match("Distribution comment")
    expect(mail.subject).to eq("test subject from DEFAULT")
  end
end
