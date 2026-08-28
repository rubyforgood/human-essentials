# A status is not an action. `data-page-header="actions"` is documented as "at most three, exactly
# one primary", which a status pill is none of, and a pill among buttons reads as a button that has
# been greyed out -- see design.md and the page_header partial's own comment.
#
# The bank's partner page was fixed for this once, and four partner-facing pages still had it.
# Asserted rather than left to review, because the defect is invisible until a header gains a real
# button beside the pill, at which point it looks like a disabled action.
RSpec.describe "A status in a page header", type: :system, js: true do
  let(:organization) { create(:organization) }

  def pills_in_actions
    page.evaluate_script(<<~JS)
      (() => {
        const box = document.querySelector('[data-page-header="actions"]');
        return box ? [...box.children].filter((c) => c.tagName === 'SPAN').length : 0;
      })()
    JS
  end

  context "on the bank's partner page, where the title names the partner" do
    let(:user) { create(:user, organization: organization) }
    let(:partner) { create(:partner, organization: organization, status: :approved) }

    before { login_as(user) }

    it "rides the title line and leaves the actions container to actions" do
      visit partner_path(partner)

      expect(page).to have_css("h1", text: partner.name)
      expect(page).to have_css("h1", text: "Approved")
      expect(pills_in_actions).to eq(0), "a status pill is sitting in the actions container"
    end
  end

  context "on the partner's own dashboard, where the title names the page" do
    let(:partner) { create(:partner, organization: organization, status: status) }

    before { login_as(partner.primary_user) }

    context "when the agency is approved" do
      let(:status) { :approved }

      # Nothing to say. An "Approved" pill on your own dashboard every day is noise.
      it "shows no status at all, and keeps the heading naming its page" do
        visit partners_dashboard_path

        expect(page).to have_css("h1", text: "Dashboard")
        expect(page).to have_no_css('[data-page-header="actions"]')
        expect(page).to have_no_css('[role="alert"]')
      end
    end

    context "when the agency is not approved" do
      let(:status) { :awaiting_review }

      # The request options card is hidden outright for an unapproved partner, and the pill was the
      # only thing on the page explaining that -- without ever naming the consequence.
      it "explains why requests are unavailable, in a callout rather than a pill" do
        visit partners_dashboard_path

        expect(page).to have_css("h1", text: "Dashboard")
        expect(page).to have_no_css('[data-page-header="actions"]')
        expect(page).to have_css('[role="alert"]', text: "waiting for your bank to approve it")
      end
    end
  end
end
