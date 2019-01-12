RSpec.feature "Audit management", type: :feature do
  let!(:url_prefix) { "/#{@organization.to_param}" }

  context "while signed in as a normal user" do
    before do
      sign_in(@user)
    end

    scenario "The user can not see the audits page" do
    end
  end

  context "while signed in as an organization admin" do
    before do
      sign_in(@organization_admin)
    end

    scenario "The user can see the audits summary" do
    end

    scenario "The user should be able to save progress of an audit" do
    end

    scenario "The user should be able to resume the audit that is in progress" do
    end

    scenario "The user should be able to delete the audit that is in progress" do
    end

    scenario "The user sees the confirm dialog before confirming the audit" do
    end

    scenario "The user should not be able to edit the audit that is confirmed" do
    end

    scenario "The user should be able to delete the audit that is confirmed" do
    end

    scenario "The user should be able to see the differential when the audit is not finalized" do
    end

    scenario "The user should see a dialog before finalizing the audit" do
    end

    scenario "Finalizing the audit should create an adjustment with the differential" do
    end

    scenario "The created adjustment should have a comment that says that the `Adjustment is created automatically through the Auditing process`" do
    end

    scenario "The finalized audit should be immutable" do
    end
  end
end
