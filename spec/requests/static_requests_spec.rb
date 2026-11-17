RSpec.describe "Static", type: :request do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:organization_admin) { create(:organization_admin, organization: organization) }

  describe "Not signed in" do
    describe "GET #index" do
      it "returns http success" do
        get root_path
        expect(response).to be_successful
      end
      it "renders the static index" do
        get root_path
        expect(response).to render_template :index
      end

      it "is on the public site's layout, not the app's" do
        get root_path
        expect(response).to render_template "layouts/landing"
        expect(response.body).to include("/assets/landing")
        expect(response.body).not_to include("tailwind")
        expect(response.body).not_to include("<script")
      end

      it "has a door for each kind of visitor" do
        get root_path
        page = Nokogiri::HTML(response.body)
        hrefs = page.css("a").map { |a| a["href"] }

        expect(hrefs).to include(new_account_request_path, new_user_session_path, bank_finder_path, privacypolicy_path)
        # The finder is a plain GET to the bank finder, so it works without JavaScript.
        form = page.at_css("form[action='#{bank_finder_path}']")
        expect(form["method"]).to eq("get")
        expect(form.at_css("input[name='near']")).to be_present
        # One name for each action, everywhere on the page.
        expect(response.body).not_to match(/Register|Sign ?up|Request An Account|Log In\b/)
      end

      it "describes itself to search engines and to shared links" do
        get root_path
        page = Nokogiri::HTML(response.body)

        expect(page.at_css("meta[name='description']")["content"]).to include("free inventory software")
        expect(page.at_css("meta[property='og:title']")["content"]).to eq(page.at_css("title").text)
        expect(page.at_css("meta[property='og:image']")["content"]).to match(%r{\Ahttp://www.example.com/assets/landing/share-\h+\.png\z})
        expect(page.at_css("link[rel='canonical']")["href"]).to eq(root_url)
      end

      it "has one h1, and headings that do not skip a level" do
        get root_path
        levels = Nokogiri::HTML(response.body).css("h1, h2, h3, h4, h5, h6").map { |h| h.name[1].to_i }

        expect(levels.count(1)).to eq(1)
        expect(levels.each_cons(2).all? { |a, b| b <= a + 1 }).to be(true)
      end

      it "has a tour of five steps that needs no JavaScript: a radio, its label and its screen, in that order" do
        get root_path
        tour = Nokogiri::HTML(response.body).at_css(".tour")
        parts = tour.element_children.map { |el| (el.name == "div") ? el["class"] : el.name }

        # The stylesheet shows a panel with `input:checked + label + .panel`, so the order is the mechanism.
        expect(parts).to eq(%w[input label panel] * 5)
        expect(tour.css("input[type=radio]").map { |i| i["name"] }.uniq).to eq(["step"])
        expect(tour.css("input[checked]").map { |i| i["id"] }).to eq(["step-1"])
        expect(tour.css("label b").map(&:text)).to eq(["Receive", "Store", "Hear from partners", "Distribute", "Report"])
        tour.css("label").each { |label| expect(tour.at_css("input##{label["for"]}")).to be_present }

        images = tour.css(".panel img")
        expect(images.map { |img| img["src"][%r{landing/app-(\w+)-}, 1] }).to eq(%w[donation inventory request distribution reports])
        expect(images.map { |img| img["loading"] }.uniq).to eq(["lazy"])
        expect(images.map { |img| img["alt"].to_s.length }).to all(be > 40)
      end

      context "the map" do
        it "draws one light for each located bank, and says how many" do
          create(:bank_listing, diapers: true, period_supplies: false)
          create(:bank_listing, diapers: false, period_supplies: true, latitude: 45.5371, longitude: -122.65)
          create(:bank_listing, diapers: true, period_supplies: true, city: "Carolina", state: "PR", latitude: 18.412076, longitude: -65.979806)
          create(:bank_listing, latitude: nil, longitude: nil)
          BankListing.update_all(updated_at: Time.zone.local(2026, 10, 19, 12))

          get root_path
          page = Nokogiri::HTML(response.body)

          expect(page.css("svg.map .dots circle").map { |c| c["class"] }).to match_array(%w[d p b])
          expect(page.at_css("svg.map")["aria-label"]).to include("3 points of light")
          expect(page.at_css(".map-note").text).to include("one of the 3 banks")
          expect(page.at_css("svg.map text").text).to eq("Puerto Rico")
          expect(page.at_css(".credits").text.squish).to include("as imported on October 19, 2026")
        end

        it "is only the outline, with no caption or count, before any bank is imported" do
          get root_path
          page = Nokogiri::HTML(response.body)

          expect(response).to be_successful
          expect(page.at_css("svg.map path.land")).to be_present
          expect(page.css("svg.map circle, svg.map text, .map-note, .legend, .credits")).to be_empty
        end
      end
    end

    describe "GET #page/privacypolicy" do
      it "renders the contact page" do
        get privacypolicy_path
        expect(response).to render_template :privacypolicy
      end

      it "is the policy, on the public site's layout" do
        get privacypolicy_path
        page = Nokogiri::HTML(response.body)

        expect(response).to render_template "layouts/landing"
        expect(page.css("h1").map(&:text)).to eq(["Privacy Policy"])
        expect(page.css("main h2").map(&:text)).to eq([
          "Information Collection And Use", "Log Data", "Communications", "Cookies", "Security",
          "Changes To This Privacy Policy", "Contact Us"
        ])
        expect(page.at_css("main").text).to include("We use your Personal Information only for providing and improving the Site.")
        expect(page.at_css("a[href='mailto:info@humanessentials.app']")).to be_present
      end
    end
  end

  describe "Signed in" do
    before do
      sign_in(user)
    end

    describe "GET #index" do
      it "redirects to organization dashboard" do
        get root_path
        expect(response).to redirect_to(dashboard_url)
      end
    end

    describe "GET #page/index" do
      it "shows the landing page to someone who is signed in" do
        get "/pages/index"
        expect(response).to be_successful
        expect(response.body).to include("The free system behind more than 200 essentials banks.")
      end
    end
  end

  describe "Non super user without org signed in" do
    let(:user_no_org) { User.create(email: "no-org-user@example.org2", password: "password!") }
    before do
      user_no_org.add_role(:org_user)
      sign_in(user_no_org)
    end

    describe "GET #index" do
      it "redirects to a public/403.html page" do
        get root_path
        expect(response).to redirect_to("/403")
      end
    end
  end

  describe "Super user without org signed in" do
    before do
      sign_in(create(:super_admin, organization: nil))
    end

    describe "GET #index" do
      it "redirects to admin dashboard" do
        get root_path

        expect(response).to redirect_to(admin_dashboard_url)
      end
    end
  end
end
