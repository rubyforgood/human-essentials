require 'rails_helper'

RSpec.describe "DonationSites", type: :request do
    let(:default_params) do
        { organization_id: @organization.to_param }
    end

    context "while signed in" do
        before do
            sign_in(@user)
        end

        describe "GET #index" do
            it "returns http success" do
                get donation_sites_path(default_params)
                expect(response).to be_successful

                expect(response).to render_template(:index)
            end
        end

        describe "GET #new" do
            it "returns http success" do
                get new_donation_site_path(default_params)
                expect(response).to be_successful
                
                expect(response).to render_template(:new)
            end
        end

        describe "POST #create" do

            it "flashes an error" do
                new_params = default_params.merge(donation_site: { name: "Plain old site"})

                post donation_sites_path(new_params)
                expect(response).to be_successful
                expect(response).to have_error(/try again?/i)
            end
            
        end 

        describe "GET #edit" do
            it "returns http success" do
                editable = default_params.merge(id: create(:donation_site, organization: @organization))
                get edit_donation_site_path(editable) 
                expect(response).to be_successful
            end
        end

        describe "GET #show" do
            it "returns http success" do
                site = default_params.merge(id: create(:donation_site, organization: @organization))
                get donation_site_path(site)
                expect(response).to be_successful
                expect(response).to render_template(:show)
            end

            it "returns 404 for unknown entity" do
                fake = default_params.merge(id: "fake")
                get donation_site_path(fake)
                expect(response).to_not render_template(:show)
            end
        end

        describe "DELETE #destroy" do
            
            it "returns http success" do
                delete_soon = default_params.merge(id: create(:donation_site, organization: @organization))
                delete donation_site_path(delete_soon)

                expect(response).to have_http_status(302)
                expect(response).to redirect_to(donation_sites_path)
            end
        end

    end

    context "While not signed in" do
        let(:object) { create(:donation_site) }
        include_examples "requiring authorization"
    end
end
