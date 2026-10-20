RSpec.describe BankListingMailer, type: :mailer do
  it "tells every super admin why the list was kept" do
    create(:super_admin, email: "one@example.com")
    create(:super_admin, email: "two@example.com")
    mail = described_class.import_failed(error: "The diapers directory had no banks in it.")

    expect(mail.to).to match_array(%w[one@example.com two@example.com])
    expect(mail.subject).to eq("[Human Essentials] The bank finder kept last week's list")
    expect(mail.text_part.body.to_s).to include("The diapers directory had no banks in it.", "/find-a-bank")
  end
end
