# The landing page is the one page of the app most people ever see, and it loads no JavaScript,
# so what a browser does with its plain links, form and <details> is the whole of how it works.
RSpec.describe "Landing page", type: :system, js: true do
  before do
    create_census_locations
    import_sample_bank_listings
  end

  it "takes someone who runs a bank to the account request form" do
    visit root_path

    expect(page).to have_css("h1", text: "The free system behind more than 200 essentials banks.")
    within(".hero") { click_link "Request an account" }

    expect(page).to have_current_path(new_account_request_path)
  end

  it "takes someone at a partner agency to the log in page" do
    visit root_path
    within("header") { click_link "Log in" }

    expect(page).to have_current_path(new_user_session_path)
  end

  it "finds a bank for someone who needs supplies, from the field under the map" do
    visit root_path

    fill_in "Looking for diapers or period supplies?", with: "Dayton, OH"
    click_button "Find a bank"

    expect(page).to have_current_path(bank_finder_path(near: "Dayton, OH"))
    expect(page).to have_css("h1", text: "Banks near Dayton, OH")
    expect(page).to have_css("#bank-finder-results", text: "Pawnee Diaper Bank")
  end

  it "opens the bank finder when the field is left empty" do
    visit root_path
    click_button "Find a bank"

    expect(page).to have_css("h1", text: "Find a bank near you")
  end

  it "draws a light on the map for each bank in the directories" do
    visit root_path

    expect(page).to have_css("svg.map .dots circle", count: BankListing.located.count, visible: :all)
    expect(page).to have_css(".map-note", text: "Each light is one of the #{BankListing.located.count} banks")
  end

  context "the tour of five steps" do
    let(:shown) { -> { page.all(".tour .panel img", visible: true).map { |img| img[:src][%r{app-(\w+)-}, 1] } } }

    it "shows the first step's screen, and another's when that step is chosen" do
      visit root_path

      expect(page).to have_css(".tour .panel", count: 1)
      expect(shown.call).to eq(["donation"])
      expect(page).to have_css(".tour .about h3", text: "What came in, and what it is worth.")

      find(".tour label", text: "Distribute").click

      expect(page).to have_css(".tour .about h3", text: "From request to pick up.")
      expect(shown.call).to eq(["distribution"])
      expect(page).to have_no_text("What came in, and what it is worth.")
    end

    it "loads a screen's picture only when its step is chosen" do
      visit root_path
      loaded = -> { page.evaluate_script("[...document.querySelectorAll('.tour img')].filter(i => i.complete && i.naturalWidth > 0).length") }
      find(".tour").scroll_to(:center)

      expect(page).to have_css(".tour .panel", count: 1)
      page.document.synchronize { raise Capybara::ExpectationNotMet, "#{loaded.call} loaded" unless loaded.call == 1 }

      find(".tour label", text: "Report").click
      page.document.synchronize { raise Capybara::ExpectationNotMet, "#{loaded.call} loaded" unless loaded.call == 2 }
    end

    it "moves between steps with the arrow keys, as a radio group does" do
      visit root_path
      page.execute_script("document.getElementById('step-1').focus()")

      page.driver.browser.keyboard.type(:Right)
      expect(page).to have_css(".tour .about h3", text: "Every storage location, counted.")
      expect(page.evaluate_script("document.activeElement.id")).to eq("step-2")

      page.driver.browser.keyboard.type(:Left)
      expect(page).to have_css(".tour .about h3", text: "What came in, and what it is worth.")
    end

    it "has nothing to choose on a phone: every step is followed by its screen" do
      page.driver.resize(390, 844)
      visit root_path

      expect(page).to have_css(".tour .panel", count: 5)
      expect(shown.call).to eq(%w[donation inventory request distribution reports])
      # The radios are gone, not just hidden, so the keyboard does not stop on them.
      expect(page).to have_no_css(".tour input", visible: true)
      expect(page.evaluate_script("getComputedStyle(document.getElementById('step-1')).display")).to eq("none")
      expect(page.evaluate_script("document.documentElement.scrollWidth")).to eq(390)
    ensure
      page.driver.resize(1200, 800)
    end
  end

  it "answers a question when it is opened" do
    visit root_path
    answer = "There is no charge to any bank."

    expect(page).to have_no_text(answer)
    find("summary", text: "Is it really free?").click
    expect(page).to have_text(answer)
  end

  it "moves down the page from the header's links" do
    visit root_path
    within("header") { click_link "Questions" }

    expect(page.evaluate_script("location.hash")).to eq("#questions")
    # The scroll is smooth, so wait for it to arrive rather than measuring once.
    page.document.synchronize do
      top = page.evaluate_script("document.getElementById('questions').getBoundingClientRect().top")
      raise Capybara::ExpectationNotMet, "#questions is #{top}px from the top" unless top.between?(0, 200)
    end
  end

  it "fits a phone without scrolling sideways" do
    page.driver.resize(390, 844)
    visit root_path

    expect(page.evaluate_script("document.documentElement.scrollWidth")).to eq(390)
    expect(page).to have_css("header a", text: "Log in")
  ensure
    page.driver.resize(1200, 800)
  end

  # The map leans into the page's margin, and at these widths the margin was narrower than the lean.
  it "does not scroll sideways at any width between a small phone and a wide desk" do
    [320, 768, 991, 992, 1024, 1100, 1247, 1248, 1279, 1280, 1440, 1920].each do |width|
      page.driver.resize(width, 800)
      visit root_path
      overflow = page.evaluate_script("document.documentElement.scrollWidth - document.documentElement.clientWidth")
      expect(overflow).to eq(0), "#{overflow}px of sideways scroll at #{width}px wide"
    end
  ensure
    page.driver.resize(1200, 800)
  end

  it "reaches the privacy policy and comes back" do
    visit root_path
    within(".footer") { click_link "Privacy policy" }

    expect(page).to have_css("h1", text: "Privacy Policy")
    click_link "Human Essentials", match: :first
    expect(page).to have_current_path(root_path)
  end
end
