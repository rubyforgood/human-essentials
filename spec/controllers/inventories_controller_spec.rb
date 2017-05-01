require 'rails_helper'

RSpec.describe InventoriesController, type: :controller do

  describe "GET #index" do
    subject { get :index }
    it "returns http success" do
      expect(subject).to be_successful
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

  describe "GET #destroy" do
    subject { delete :destroy, params: { id: create(:inventory) } }
    it "redirects to #index" do
      expect(subject).to redirect_to(inventories_path)
    end
  end

end
