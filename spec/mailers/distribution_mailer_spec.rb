require "rails_helper"

RSpec.describe DistributionMailer, type: :mailer do
  describe "partner_mailer" do
    let(:mail) { DistributionMailer.partner_mailer }

    it "renders the headers" do
      expect(mail.subject).to eq("Partner mailer")
      expect(mail.to).to eq(["to@example.org"])
      expect(mail.from).to eq(["from@example.com"])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("Hi")
    end
  end

end
