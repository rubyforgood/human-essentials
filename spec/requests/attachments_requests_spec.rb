RSpec.describe "Attachments", type: :request do
  before do
    sign_in(@user)
  end

  describe "DELETE #destroy" do
    let(:partner) { create(:partner, attached_documents: %w[spec/fixtures/files/dbase.pdf]) }

    it "redirects to referrer" do
      delete attachment_path(partner.documents.first)
      expect(response).to redirect_to(partners_path)
    end
  end
end
