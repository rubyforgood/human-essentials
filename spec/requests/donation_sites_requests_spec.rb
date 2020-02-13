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
            xit "succesfully creates donation site" do
                Geocoder.configure(:lookup => :test)
                # new_address = Geocoder::Lookup::Test.add_stub("Bayfield, CO", [{ "name" => "Plain old site",
                #                         "address" => "123 Somewhere St, Bayfield, CO 81122"}])

                new_address =   Geocoder::Lookup::Test.add_stub(
                                "Los Angeles, CA", [{
                                                        "latitude"    => 34.052363,
                                                        "longitude"    => -118.256551,
                                                        "address"      => 'Los Angeles, CA, USA',
                                                        "state"        => 'California',
                                                        "state_code"   => 'CA',
                                                        "country"      => 'United States',
                                                        "country_code" => 'US'
                                                    }]

                                                    )
                new_params = default_params.merge(donation_site: new_address[0])
                binding.pry
                post donation_sites_path(new_params)
                expect(response).to be_successful
            end

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

    end

    context "While not signed in" do
        let(:object) { create(:donation_site) }
        include_examples "requiring authorization"
    end
end
