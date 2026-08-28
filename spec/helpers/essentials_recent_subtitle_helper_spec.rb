# The admin dashboard's "recently added" cards used to carry a status pill in the card header's
# `actions:` slot. It was wrong three ways -- a count is not a status, a status is not an action,
# and the number was `@recent_users.count` where `@recent_users` is `.limit(20)`, so it reported the
# cap as the total: "20 new users" with 23 signed up.
#
# The last of those is the one worth a spec, because it is the one that was *false* rather than
# merely misplaced, and it is silent -- it only misreports once the list overflows, which no one is
# looking at on the day the limit is added.
RSpec.describe EssentialsUiHelper, type: :helper do
  describe "#essentials_recent_subtitle" do
    it "names the period when the list is the whole of it" do
      expect(helper.essentials_recent_subtitle(3)).to eq("Added in the last week.")
    end

    it "says so when the list is only the top of a longer one" do
      expect(helper.essentials_recent_subtitle(20, total: 23, noun: "users"))
        .to eq("The 20 most recent of 23 users added in the last week.")
    end

    # The bug in one line: a capped count equal to the cap must not read as a total.
    it "does not claim a capped count is the total" do
      expect(helper.essentials_recent_subtitle(20, total: 23, noun: "users")).to include("of 23")
    end

    it "treats an equal total as no truncation" do
      expect(helper.essentials_recent_subtitle(20, total: 20, noun: "users"))
        .to eq("Added in the last week.")
    end

    it "delimits large numbers" do
      expect(helper.essentials_recent_subtitle(20, total: 1234, noun: "users"))
        .to eq("The 20 most recent of 1,234 users added in the last week.")
    end

    it "reads as the whole period when nothing was added" do
      expect(helper.essentials_recent_subtitle(0)).to eq("Added in the last week.")
    end
  end
end
