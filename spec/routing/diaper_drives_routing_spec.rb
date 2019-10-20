require "rails_helper"

RSpec.describe DiaperDrivesController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(:get => "/diaper_drives").to route_to("diaper_drives#index")
    end

    it "routes to #new" do
      expect(:get => "/diaper_drives/new").to route_to("diaper_drives#new")
    end

    it "routes to #show" do
      expect(:get => "/diaper_drives/1").to route_to("diaper_drives#show", :id => "1")
    end

    it "routes to #edit" do
      expect(:get => "/diaper_drives/1/edit").to route_to("diaper_drives#edit", :id => "1")
    end


    it "routes to #create" do
      expect(:post => "/diaper_drives").to route_to("diaper_drives#create")
    end

    it "routes to #update via PUT" do
      expect(:put => "/diaper_drives/1").to route_to("diaper_drives#update", :id => "1")
    end

    it "routes to #update via PATCH" do
      expect(:patch => "/diaper_drives/1").to route_to("diaper_drives#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/diaper_drives/1").to route_to("diaper_drives#destroy", :id => "1")
    end
  end
end
