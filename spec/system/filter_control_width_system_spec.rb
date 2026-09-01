RSpec.describe "Filter control width", type: :system, js: true do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }

  before { sign_in user }

  it "fills its grid cell, so the gap between two filters is the grid's" do
    # Reported as too much padding between the two. The bar lays its controls out on a grid with a
    # 12px gap and 271px cells; both triggers carried `sm:w-64`, so each sat 15px narrow inside its
    # cell and the gap read as 27. design.md already said it: "the inline controls use the panel's
    # own grid, so a control is the same width whether the bar folds or not."
    visit historical_trends_distributions_path
    expect(page).to have_css("#filters_compare_trigger")

    measured = page.evaluate_script(<<~JS)
      (() => {
        const m = document.querySelector("#filters_months_trigger");
        const c = document.querySelector("#filters_compare_trigger").closest("[data-controller~='compare-picker']");
        const grid = document.querySelector("main form .grid");
        if (!m || !c || !grid) return null;
        return { gap: Math.round(c.getBoundingClientRect().left - m.getBoundingClientRect().right),
                 gridGap: parseFloat(getComputedStyle(grid).columnGap) };
      })()
    JS

    expect(measured).not_to be_nil
    expect(measured["gap"]).to eq(measured["gridGap"])
  end
end
