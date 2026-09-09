RSpec.describe "Transfers", type: :request do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }

  before { sign_in(user) }

  describe "GET #index" do
    let!(:transfer) { create(:transfer, organization: organization) }

    it "renders the View button before the Undo button" do
      get transfers_path

      # Bootstrap Icons, not Font Awesome: ADR 0011 removed the latter.
      view_position = response.body.index("bi-eye")
      undo_position = response.body.index("bi-arrow-counterclockwise")

      expect(view_position).to be_present
      expect(undo_position).to be_present
      expect(view_position).to be < undo_position
    end

    it "labels the destructive action as Undo with the undo icon" do
      get transfers_path

      expect(response.body).to include("Undo")
      expect(response.body).to include("bi-arrow-counterclockwise")
      expect(response.body).not_to include("bi-trash")
    end

    it "asks for confirmation worded as an undo" do
      get transfers_path

      expect(response.body).to include("Are you sure you want to undo this transfer?")
    end
  end
end
