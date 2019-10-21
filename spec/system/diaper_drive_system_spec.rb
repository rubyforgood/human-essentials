RSpec.describe "Diaper Drives", type: :system, js: true do
  before do
    sign_in @user
    @url_prefix = "/#{@organization.short_name}"
  end
  context "When visiting the index page" do
    before(:each) do
      create(:diaper_drive)
    end
  end
end