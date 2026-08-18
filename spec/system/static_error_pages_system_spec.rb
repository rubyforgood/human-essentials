require "rails_helper"

# These pages are served straight off disk -- by the static middleware for /403, and by the
# server as a last resort when Rails itself cannot render. So they must not depend on the asset
# pipeline or load any JavaScript: whatever is broken enough to reach them may be the very thing
# that would break a page needing assets.
RSpec.describe "Static Error Pages", type: :system do
  {
    "403" => "Access denied",
    "404" => "Page not found",
    "422" => "Change rejected",
    "500" => "Something went wrong"
  }.each do |code, heading|
    describe "/#{code}" do
      before { visit "/#{code}" }

      it "says what happened, and shows the status code" do
        expect(page).to have_css("h1", text: heading)
        expect(page).to have_text(code)
      end

      it "offers a way back into the app" do
        expect(page).to have_link("Back to Human Essentials", href: "/")
      end

      it "loads no scripts and no stylesheets" do
        expect(page).to have_no_css("script", visible: :all)
        expect(page).to have_no_css("link[rel='stylesheet']", visible: :all)
      end
    end
  end
end
