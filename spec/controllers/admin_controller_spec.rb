RSpec.describe AdminController, type: :controller do
  context "while signed in as a super admin" do
    before do
      sign_in(@super_admin)
    end
  end
end