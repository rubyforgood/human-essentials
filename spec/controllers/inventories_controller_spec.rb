require 'rails_helper'

RSpec.describe InventoriesController, type: :controller do

  describe "GET #index" do
    subject { get :index }
    it "returns http success" do
      expect(subject).to be_successful
    end
  end

  describe "GET #create" do
    subject { post :create, params: { inventory: attributes_for(:inventory) } }
    it "redirects to #show" do
      pending "This should be moved to a feature spec"
      expect(subject).to redirect_to(:show_path)
    end
  end

  describe "GET #new" do
    subject { get :new }
    it "returns http success" do
      expect(subject).to be_successful
    end
  end

  describe "GET #edit" do
    subject { get :edit, params: { id: create(:inventory) } }
    it "returns http success" do
      expect(subject).to be_successful
    end
  end

  describe "GET #show" do
    subject { get :show, params: { id: create(:inventory) } }
    it "returns http success" do
      expect(subject).to be_successful
    end
  end

  describe "PUT #update" do
    subject { put :update, params: { id: create(:inventory), inventory: attributes_for(:inventory) } }
    it "returns http success" do
      pending("This should be moved to a feature spec")
      expect(subject).to redirect_to(:show_path)
    end
  end

  describe "GET #destroy" do
    subject { delete :destroy, params: { id: create(:inventory) } }
    it "redirects to #index" do
      expect(subject).to redirect_to(inventories_path)
    end
  end

end
