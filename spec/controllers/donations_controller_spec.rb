require 'rails_helper'

RSpec.describe DonationsController, type: :controller do

  describe "PATCH #add_item" do
    subject { patch :add_item, params: { id: create(:donation) } }
    it "returns http success" do
      pending "This should be moved to a feature spec"
      expect(subject).to have_http_status(:success)
    end
  end

  describe "PATCH #remove_item" do
    subject { patch :remove_item, params: { id: create(:donation) } }
    it "returns http success" do
      pending "This should be moved to a feature spec"
      expect(subject).to have_http_status(:success)
    end
  end

  describe "PATCH #complete" do
    subject { patch :complete, params: { id: create(:donation) } }
    it "returns http success" do
      pending "This should be moved to a feature spec"
      request.env["HTTP_REFERER"]
      expect(subject).to have_http_status(:success)
    end
  end

  describe "GET #index" do
    subject { get :index }
    it "returns http success" do
      expect(subject).to be_successful
    end
  end

  describe "POST #create" do
    subject { post :create, { donation: attributes_for(:donation) } }
    it "redirects to #show" do
      pending("This should be moved to a feature spec")
      raise 
    end
  end

  describe "GET #new" do
    subject { get :new }
    it "returns http success" do
      expect(subject).to be_successful
    end
  end

  describe "GET #edit" do
    subject { get :edit, params: { id: create(:donation) } }
    it "returns http success" do
      expect(subject).to have_http_status(:success)
    end
  end

  describe "GET #show" do
    subject { get :show, params: { id: create(:donation) } }
    it "returns http success" do
      expect(subject).to be_successful
    end
  end

  describe "PUT #update" do
    subject { put :update, params: { id: create(:donation) } }
    it "redirects to #show" do
      pending("This should be moved to a feature spec")
      raise
    end
  end

  describe "DELETE #destroy" do
    subject { delete :destroy, params: { id: create(:donation) } }
    it "redirecst to the index" do
      expect(subject).to redirect_to(donations_path)
    end
  end


end
