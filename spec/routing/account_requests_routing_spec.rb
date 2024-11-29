RSpec.describe AccountRequestsController, type: :routing do
  describe "routing" do
    it "routes to #new" do
      expect(get: "/account_requests/new").to route_to("account_requests#new")
    end

    it "routes to #create" do
      expect(post: "/account_requests").to route_to("account_requests#create")
    end
  end
end
