require 'rails_helper'

RSpec.describe TicketsController, type: :controller do

  describe "GET #print" do
    subject { get :print, params: { id: create(:ticket) } }
    it "returns http success" do
      expect(subject).to be_successful
    end
  end

  describe "GET #reclaim" do
    subject { get :reclaim, { id: create(:ticket) } }
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
    subject { post :create, params: { ticket: attributes_for(:ticket) } }
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
    subject { get :show, params: { id: create(:ticket) } }
    it "returns http success" do
      expect(subject).to be_successful
    end
  end

end
