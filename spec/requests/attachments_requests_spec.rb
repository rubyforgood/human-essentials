RSpec.describe "Attachments", type: :request do
  let(:organization) { create(:organization) }

  before do
    sign_in(create(:user, organization: organization))
  end

  describe "DELETE #destroy" do
    let(:partner) { create(:partner, organization: organization, documents: [Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/dbase.pdf"), "application/pdf")]) }

    it "redirects to referrer" do
      delete attachment_path(partner.documents.first)
      expect(response).to redirect_to(partners_path)
    end

    it "does not delete another organization's partner documents" do
      other_partner = create(:partner, organization: create(:organization), documents: [Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/dbase.pdf"), "application/pdf")])
      attachment = other_partner.documents.first
      delete attachment_path(attachment)
      expect(response).to have_http_status(:not_found)
      expect(ActiveStorage::Attachment.exists?(attachment.id)).to be(true)
    end

    it "does not delete attachments that are not partner documents" do
      organization.logo.attach(io: Rails.root.join("spec/fixtures/files/logo.jpg").open, filename: "logo.jpg")
      attachment = organization.logo.attachment
      delete attachment_path(attachment)
      expect(response).to have_http_status(:not_found)
      expect(ActiveStorage::Attachment.exists?(attachment.id)).to be(true)
    end
  end
end
