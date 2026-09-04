RSpec.describe EssentialsUiHelper, type: :helper do
  describe "#essentials_invitation_status_pill" do
    # One helper for the bank's organization table and the partner's user table. They rendered the
    # same `User#invitation_status` two ways, and disagreed about the states: the partner side
    # computed from `invitation_accepted_at` alone, so a user who had signed in read "Accepted"
    # there and "joined" on /organization.
    def pill_for(user)
      Nokogiri::HTML.fragment(helper.essentials_invitation_status_pill(user)).at("span")
    end

    it "distinguishes a user who has signed in from one who only accepted" do
      joined = build(:user, current_sign_in_at: Time.current, invitation_accepted_at: 1.day.ago)
      accepted = build(:user, current_sign_in_at: nil, invitation_accepted_at: 1.day.ago)

      expect(pill_for(joined).text.strip).to eq("Joined")
      expect(pill_for(accepted).text.strip).to eq("Accepted")
    end

    it "shows an outstanding invitation as Invited, in the warning tone" do
      invited = build(:user, current_sign_in_at: nil, invitation_accepted_at: nil,
        invitation_sent_at: 2.days.ago)

      pill = pill_for(invited)
      expect(pill.text.strip).to eq("Invited")
      expect(pill["class"]).to include(EssentialsUiHelper::PILL_TONES[:warning])
    end

    # `invitation_status` returns nil for an account created directly rather than invited. That
    # rendered as an empty cell on /organization, which left the reader to guess.
    it "names the never-invited case instead of rendering nothing" do
      direct = build(:user, current_sign_in_at: nil, invitation_accepted_at: nil,
        invitation_sent_at: nil)

      pill = pill_for(direct)
      expect(pill.text.strip).to eq("Not invited")
      expect(pill["class"]).to include(EssentialsUiHelper::PILL_TONES[:neutral])
    end

    it "always renders a pill, so the column never has an empty cell" do
      [Time.current, nil].each do |signed_in|
        [1.day.ago, nil].each do |accepted|
          [2.days.ago, nil].each do |sent|
            user = build(:user, current_sign_in_at: signed_in, invitation_accepted_at: accepted,
              invitation_sent_at: sent)
            expect(pill_for(user)).to be_present
          end
        end
      end
    end
  end
end
