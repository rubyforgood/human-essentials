require 'rails_helper'

RSpec.describe BarcodeItemsController, type: :controller do

  describe "GET #index" do
    subject { get :index }
    it "returns http success" do
      expect(subject).to have_http_status(:success)
    end
  end

  describe "POST #create" do
    subject { post :create, { barcode_item: attributes_for(:barcode_item) } }
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
    subject { get :edit, params: { id: create(:barcode_item) } }
    it "returns http success" do
      expect(subject).to have_http_status(:success)
    end
  end

  describe "GET #show" do
    subject { get :show, params: { id: create(:barcode_item) } }
    it "returns http success" do
      expect(subject).to be_successful
    end
  end

  describe "PUT #update" do
    subject { put :update, params: { id: create(:barcode_item) } }
    it "redirects to #show" do
      pending("This should be moved to a feature spec")
      raise
    end
  end

  describe "DELETE #destroy" do
    subject { delete :destroy, params: { id: create(:barcode_item) } }
    it "redirecst to the index" do
      expect(subject).to redirect_to(barcode_items_path)
    end
  end

end
