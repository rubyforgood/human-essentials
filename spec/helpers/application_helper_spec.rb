RSpec.describe ApplicationHelper, type: :helper do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }

  describe "default_title_content" do
    helper do
      def current_organization; end
    end

    before(:each) do
      allow(helper).to receive(:current_organization).and_return(organization)
    end

    context "Organization exists" do
      it "returns the organization's name" do
        expect(helper.default_title_content).to eq organization.name
      end
    end

    context "Organization does not exist" do
      let(:organization) { nil }

      it "returns a default name" do
        expect(helper.default_title_content).to eq "Humanessentials"
      end
    end
  end

  describe "active_class" do
    it "Is not active with another controller" do
      expect(params).to receive(:[]).with(:controller).twice.and_return("bar")
      expect(params).to receive(:[]).with(:action).and_return(nil)
      expect(helper.active_class(["foo"])).to eq ""
    end

    it "Is active with the current controller" do
      expect(params).to receive(:[]).with(:controller).and_return("foo")
      expect(helper.active_class(["foo"])).to eq "active"
    end
  end

  describe "can_administrate?" do
    let(:org_1) { organization }
    let(:org_2) { create(:organization) }

    helper do
      def current_organization; end
    end

    before(:each) do
      allow(helper).to receive(:current_organization).and_return(org_1)
    end

    before(:each) do
      allow(helper).to receive(:current_user).and_return(user)
    end

    context "User is org admin and part of org" do
      let(:user) { create :organization_admin, organization: org_1 }

      it "can administrate" do
        expect(helper.can_administrate?).to be_truthy
      end
    end

    context "User is org admin and not part of org" do
      let(:user) { create :organization_admin, organization: org_2 }

      it "cannot administrate" do
        expect(helper.can_administrate?).to be_falsy
      end
    end

    context "User is part of org but not org admin" do
      let(:user) { create :user, organization: org_1 }

      it "cannot administrate" do
        expect(helper.can_administrate?).to be_falsy
      end
    end
  end

  describe "flash_class" do
    it "returns appropriate class for notice" do
      expect(helper.flash_class("notice")).to match(/alert|alert-info/)
    end

    it "returns appropriate class for success" do
      expect(helper.flash_class("success")).to match(/alert|alert-success/)
    end

    it "returns appropriate class for error" do
      expect(helper.flash_class("error")).to match(/alert|alert-danger/)
    end

    it "returns appropriate class for alert" do
      expect(helper.flash_class("alert")).to match(/alert|alert-warning/)
    end
  end

  describe "confirm_delete_msg" do
    let(:item) { "Adult Briefs (Medium/Large)" }

    it "subs in string" do
      expect(helper.confirm_delete_msg(item)).to include(item)
    end
  end

  describe "step_container_helper" do
    context "active_index is equal to index" do
      let(:active_index) { 1 }
      let(:index) { 1 }

      it "returns active" do
        expect(helper.step_container_helper(index, active_index)).to include("active")
      end
    end

    context "active_index is greater than index" do
      let(:active_index) { 2 }
      let(:index) { 1 }

      it "returns done" do
        expect(helper.step_container_helper(index, active_index)).to include("done")
      end
    end

    context "active_index is less than index" do
      let(:active_index) { 0 }
      let(:index) { 1 }

      it "returns empty string" do
        expect(helper.step_container_helper(index, active_index)).to eq("")
      end
    end
  end
end
