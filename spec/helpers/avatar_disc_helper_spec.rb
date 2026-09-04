RSpec.describe EssentialsUiHelper, type: :helper do
  describe "#essentials_avatar_disc" do
    def disc_for(user)
      Nokogiri::HTML.fragment(helper.essentials_avatar_disc(user)).at("span")
    end

    it "uses the initials of the user's name" do
      expect(disc_for(build(:user, name: "Ada Lovelace")).text.strip).to eq("AL")
    end

    # The defect this covers. Both top bars passed `display_name`, which returns the literal
    # "Name Not Provided" when the name is blank -- so a nameless user's avatar read "NN". The
    # partner bar appeared to guard against it with `display_name.presence || email`, but
    # `display_name` is never blank, so that fallback never ran and it showed "NN" as well.
    it "falls back to the email, not to the initials of 'Name Not Provided'" do
      nameless = build(:user, name: "", email: "jane.doe@example.com")

      expect(disc_for(nameless).text.strip).to eq("J")
      expect(disc_for(nameless).text.strip).not_to eq("NN")
    end

    it "is hidden from assistive technology, because the trigger already names the user" do
      expect(disc_for(build(:user, name: "Ada Lovelace"))["aria-hidden"]).to eq("true")
    end

    # Same shape as `essentials_step_number` at a different size, deliberately not the same helper.
    it "renders at the avatar size, not the step-number size" do
      classes = disc_for(build(:user, name: "Ada Lovelace"))["class"]

      expect(classes).to include("h-8", "w-8", "rounded-full")
      expect(classes).not_to include("h-5")
    end
  end
end
