require 'rails_helper'

RSpec.describe DropoffLocationsController, type: :controller do

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
    subject { get :edit, params: { id: create(:dropoff_location) } }
    it "returns http success" do
      expect(subject).to be_successful
    end
  end

  describe "GET #show" do
    subject { get :show, params: { id: create(:dropoff_location) } }
    it "returns http success" do
      expect(subject).to be_successful
    end
  end

  describe "DELETE #destroy" do
    subject { delete :destroy, params: { id: create(:dropoff_location) } }
    it "returns http success" do
      expect(subject).to redirect_to(dropoff_locations_path)
    end
  end

end
