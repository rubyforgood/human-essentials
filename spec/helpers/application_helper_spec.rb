require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "dashboard_path_from_user" do
    before(:each) do
      allow(helper).to receive(:current_user).and_return(user)
    end

    context "As a super admin" do
      let(:user) { create :super_admin }

      it "links to the admin dashboard" do
        expect(helper.dashboard_path_from_user).to eq "/admin/dashboard"
      end
    end

    context "As a user without super admin status" do
      let(:user) { create :organization_admin }

      it "links to the general dashboard" do
        org_name = user.organization.short_name
        expect(helper.dashboard_path_from_user).to eq "/#{org_name}/dashboard"
      end
    end
  end

  describe "default_title_content" do
    helper do
      def current_organization; end
    end

    before(:each) do
      allow(helper).to receive(:current_organization).and_return(organization)
    end

    context "Organization exists" do
      let(:organization) { create :organization }

      it "returns the organization's name" do
        expect(helper.default_title_content).to eq organization.name
      end
    end

    context "Organization does not exist" do
      let(:organization) { nil }

      it "returns a default name" do
        expect(helper.default_title_content).to eq "DiaperBank"
      end
    end
  end

  describe "active_class" do
    it "Returns the controller name" do
      expect(helper.active_class("foo")).to eq "test"
    end
  end

  describe "can_administrate?" do
    let(:org_1) { @organization }
    let(:org_2) { create :organization }

    before(:each) do
      allow(helper).to receive(:current_user).and_return(user)
    end

    context "User is org admin and part of org" do
      let(:user) { create :user, organization_admin: true, organization: org_1 }

      it "can administrate" do
        expect(helper.can_administrate?).to be_truthy
      end
    end

    context "User is org admin and not part of org" do
      let(:user) { create :user, organization_admin: true, organization: org_2 }

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
      expect(helper.flash_class("notice")).to eq "alert alert-info"
    end

    it "returns appropriate class for success" do
      expect(helper.flash_class("success")).to eq "alert alert-success"
    end

    it "returns appropriate class for error" do
      expect(helper.flash_class("error")).to eq "alert alert-danger"
    end

    it "returns appropriate class for alert" do
      expect(helper.flash_class("alert")).to eq "alert alert-warning"
    end
  end

  describe "after_sign_in_path_for" do
    context "User is member of organization" do
      let(:user) { create :user }

      it "redirects to a user's dashboard" do
        expect(helper.after_sign_in_path_for(user)).to eq dashboard_path(user.organization.id)
      end
    end

    context "User is not member of organization" do
      let(:user) { create :user, organization_id: nil }

      it "redirects to a user's dashboard" do
        pending("TODO - figure out why stored_location_for is failing")
        expect(helper.after_sign_in_path_for(user)).to eq new_organization_path
      end
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
