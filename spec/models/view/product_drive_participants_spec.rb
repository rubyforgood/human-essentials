RSpec.describe View::ProductDriveParticipants do
  describe "selected filter params" do
    it "returns the given filter params" do
      organization = build(:organization)
      build(:product_drive_participant, organization:)
      params = ActionController::Parameters.new(
      {
        filters: {
          by_business_name: "The Good Place",
          by_contact_name: "Jason Mendoza"
        }
      }
    ).permit!

      requests = View::ProductDriveParticipants.new(params:, organization:)

      expect(requests.selected_business_name).to eq("The Good Place")
      expect(requests.selected_contact_name).to eq("Jason Mendoza")
    end
  end
end
