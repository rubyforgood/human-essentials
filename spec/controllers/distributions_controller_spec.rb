RSpec.describe DistributionsController, type: :controller do

  describe "GET #print" do
    subject { get :print, params: { id: create(:distribution).id } }
    it "returns http success" do
      expect(subject).to be_successful
    end
  end

  describe "GET #reclaim" do
    subject { get :reclaim, params: { id: create(:distribution).id } }
    it "returns http success" do
      expect(subject).to be_successful
    end
  end

  describe "GET #index" do
    subject { get :index }
    it "returns http success" do
      expect(subject).to be_successful
    end
  end

  describe "POST #create" do
    it "redirects to #show on success" do
      i = create(:inventory)
      p = create(:partner)
      post :create, params: { distribution: { inventory_id: i.id, partner_id: p.id } }
      d = Distribution.last
      expect(response).to redirect_to(distribution_path(d.id))
    end

    it "renders #new again on failure, with notice" do
      post :create, params: { distribution: { comment: nil, partner_id: nil, inventory_id: nil } }
      expect(response).to be_successful
      expect(flash[:notice]).to match(/error/i)
    end
  end

  describe "GET #new" do
    subject { get :new }
    it "returns http success" do
      expect(subject).to be_successful
    end
  end

  describe "GET #show" do
    subject { get :show, params: { id: create(:distribution) } }
    it "returns http success" do
      expect(subject).to be_successful
    end
  end

end
