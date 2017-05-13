

RSpec.describe TicketsController, type: :controller do

  describe "GET #print" do
    subject { get :print, params: { id: create(:ticket).id } }
    it "returns http success" do
      expect(subject).to be_successful
    end
  end

  describe "GET #reclaim" do
    subject { get :reclaim, params: { id: create(:ticket).id } }
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
      post :create, params: { ticket: { inventory_id: i.id, partner_id: p.id } }
      t = Ticket.last
      expect(response).to redirect_to(ticket_path(t.id))
    end

    it "renders #new again on failure, with notice" do
      post :create, params: { ticket: { comment: nil, partner_id: nil, inventory_id: nil } }
      t = Ticket.last
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
    subject { get :show, params: { id: create(:ticket) } }
    it "returns http success" do
      expect(subject).to be_successful
    end
  end

end
