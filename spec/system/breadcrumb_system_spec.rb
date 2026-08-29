RSpec.describe "Breadcrumbs", type: :system, js: true do
  let(:organization) { create(:organization) }
  let(:organization_admin) { create(:organization_admin, organization: organization) }

  before { sign_in(organization_admin) }

  def crumbs
    page.evaluate_script(<<~JS)
      [...document.querySelectorAll('nav[aria-label="Breadcrumb"] li')].map(li => {
        const a = li.querySelector("a");
        return { text: li.textContent.replace(/\\s+/g, " ").trim(),
                 href: a ? new URL(a.href).pathname : null,
                 current: !!li.querySelector("[aria-current='page']") };
      })
    JS
  end

  # The W3C ARIA APG pattern, which GOV.UK, Carbon, Material and Bootstrap all render the same
  # way: a named <nav>, an ordered list, links for ancestors, and the current page as plain text
  # carrying aria-current.
  it "is a named nav around an ordered list, ending on the current page" do
    visit edit_organization_path

    expect(page).to have_css('nav[aria-label="Breadcrumb"] > ol')
    expect(crumbs.first).to include("text" => "Dashboard", "href" => dashboard_path, "current" => false)
    expect(crumbs.last).to include("text" => "Organization settings", "href" => nil, "current" => true)
  end

  # The separator is generated and aria-hidden: a literal "/" between two links is read out as
  # "slash" by some screen readers.
  it "hides the separator from assistive technology" do
    visit edit_organization_path

    separators = page.evaluate_script(<<~JS)
      [...document.querySelectorAll('nav[aria-label="Breadcrumb"] i')]
        .map(i => i.getAttribute("aria-hidden"))
    JS
    expect(separators).not_to be_empty
    expect(separators).to all(eq("true"))
  end

  # Every report is reached from the hub and is in no menu, so before this the only way out of one
  # was the browser's back button.
  describe "the reports section" do
    it "gets back to the hub from an itemized report" do
      visit reports_itemized_donations_path

      expect(crumbs.first).to include("text" => "Reports", "href" => reports_path)
      # Scoped: the sidebar has a "Reports" link too, and it is the breadcrumb's that is on trial.
      within('nav[aria-label="Breadcrumb"]') { click_link "Reports" }
      expect(page).to have_css("h1", text: "Reports")
    end

    it "gets back to the hub from a trend page" do
      visit historical_trends_donations_path
      expect(crumbs.first).to include("text" => "Reports", "href" => reports_path)
    end

    it "gets back to the hub from the by-county report" do
      visit distributions_by_county_report_path(organization)
      expect(crumbs.first).to include("text" => "Reports", "href" => reports_path)
    end
  end

  # A report's table is a table like every other one: in a focusable, named scroll region so the
  # arrow keys scroll it and it gets the edge shadow and rail.
  it "puts a report's table in a scroll region" do
    create(:donation, :with_items, organization: organization)
    visit reports_itemized_donations_path

    expect(page).to have_css(".table-scroll[role='region'][aria-label] table.data-table")
    expect(page).to have_no_css("table.data-table.text-left")
  end
end
