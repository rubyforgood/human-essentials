require 'rails_helper'

RSpec.describe TransfersController, type: :controller do

  describe "GET #index" do
    subject { get :index }
    it "returns http success" do
      expect(subject).to be_successful
    end
  end

  describe "POST #create" do
    subject { post :create, params: { transfer: attributes_for(:transfer) } }
    it "redirects to #show" do
      pending("This should be moved to a feature spec")
      expect(subject).to redirect_to(:show_path)
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
