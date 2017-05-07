require 'rails_helper'

RSpec.describe TransfersController, type: :controller do

  describe "GET #index" do
    subject { get :index }
    it "returns http success" do
      expect(subject).to be_successful
    end
  end

  describe "POST #create" do
    it "redirects to #show when successful" do
      post :create, params: { transfer: attributes_for(:transfer) }
      t = Transfer.last
      expect(response).to redirect_to(transfer_path(t))
    end

    it "redirects to #new when failing" do
      post :create, params: { transfer: { from_id: nil, to_id: nil } }
      expect(response).to be_successful # Will render :new
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
    subject { get :show, params: { id: create(:transfer) } }
    it "returns http success" do
      expect(subject).to be_successful
    end
  end

end
