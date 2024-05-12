RSpec.describe DashboardHelper, type: :helper do
  describe "#recently_added_user_display_text" do
    context "when the user has a name" do
      it "returns the user's display name" do
        user = double("User", name: "John Doe", display_name: "John Doe", email: "john@example.com")
        expect(helper.recently_added_user_display_text(user)).to eq("John Doe")
      end
    end

    context "when the user's name is nil" do
      it "returns the user's email" do
        user = double("User", name: nil, display_name: "Name Not Provided", email: "john@example.com")
        expect(helper.recently_added_user_display_text(user)).to eq("john@example.com")
      end
    end

    context "when the user's name is blank('')" do
      it "returns the user's email" do
        user = double("User", name: "", display_name: "Name Not Provided", email: "john@example.com")
        expect(helper.recently_added_user_display_text(user)).to eq("john@example.com")
      end
    end
  end
end
