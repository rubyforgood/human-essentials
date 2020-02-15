require 'rails_helper'

RSpec.describe "Donations", type: :request do
    let(:default_params) do
        { organization_id: @organization.to_param }
      end
    let(:donation) { create(:donation, organization: @organization) }

    context "While signed in as normal user" do
        before do
            sign_in(@user)
        end

        describe "GET #index" do
            it "returns succesful index action" do
                get donations_path(default_params)
                expect(response).to be_successful
                expect(response).to render_template(:index)
            end
        end


        describe "GET #new" do
            it "returns succesful new action" do
                get new_donation_path(default_params)
                expect(response).to be_successful
                expect(response).to render_template(:new)
            end
        end


        describe "POST #create" do
            let!(:storage_location) { create(:storage_location) }
            let!(:donation_site) { create(:donation_site) }
            let(:line_items) { [attributes_for(:line_item)] }

            it "redirects to GET #edit on success" do
                new_donation = default_params.merge(
                                            donation: { storage_location_id: storage_location.id,
                                                        donation_site_id: donation_site.id,
                                                        source: "Donation Site",
                                                        line_items: line_items }
                                            )

                post donations_path(new_donation)

                expect(response).to have_http_status(302)
                expect(response).to redirect_to(donations_path)
            end

            it "renders GET#new with error on failure" do
                bad_create = default_params.merge(donation: { storage_location_id: nil, donation_site_id: nil, source: nil })

                post donations_path(bad_create)
                expect(response).to be_successful # Will render :new
                expect(response).to have_error(/error/i)
            end
        end    # End of POST create


        describe "PUT#update" do

            it "redirects to index after update" do
                donation = create(:donation_site_donation)
                params = default_params.merge(id: donation.id, donation: { source: "Donation Site", donation_site_id: donation.donation_site_id })

                put donation_path params
                expect(response).to redirect_to(donations_path)
            end

            it "updates storage quantity correctly" do
                donation = create(:donation, :with_items, item_quantity: 10)

                line_item = donation.line_items.first
                line_item_params = {
                    "0" => {
                        "_destroy" => "false",
                        item_id: line_item.item_id,
                        quantity: "15",
                        id: line_item.id
                    }
                }

                donation_params = { source: donation.source, line_items_attributes: line_item_params }
                test_params = default_params.merge(id: donation.id, donation: donation_params)
                expect do
                    put donation_path test_params
                end.to change { donation.storage_location.inventory_items.first.quantity }.by(5)
            end

            describe "when changing storage location" do
                it "updates storage quantity correctly" do
                    donation = create(:donation, :with_items, item_quantity: 10)
                    original_storage_location = donation.storage_location
                    new_storage_location = create(:storage_location)
                    line_item = donation.line_items.first

                    line_item_params = {
                        "0" => {
                        "_destroy" => "false",
                        item_id: line_item.item_id,
                        quantity: "8",
                        id: line_item.id
                        }
                    }

                    donation_params = { storage_location_id: new_storage_location.id, line_items_attributes: line_item_params }
                    test_params = default_params.merge(id: donation.id, donation: donation_params)
                    expect do
                        put donation_path test_params
                    end.to change { original_storage_location.size }.by(-10) # removes donation by 10

                    expect(new_storage_location.size).to eq 8
                end

                it "rollsback updates if quantity would go below 0" do
                    donation = create(:donation, :with_items, item_quantity: 10)
                    original_storage_location = donation.storage_location

                    # adjust inventory so that updating will set quantity below 0
                    inventory_item = original_storage_location.inventory_items.last
                    inventory_item.quantity = 5
                    inventory_item.save!

                    new_storage_location = create(:storage_location)
                    line_item = donation.line_items.first

                    line_item_params = {
                        "0" => {
                        "_destroy" => "false",
                        item_id: line_item.item_id,
                        quantity: "1",
                        id: line_item.id
                        }
                    }

                    donation_params = { source: donation.source, storage_location: new_storage_location, line_items_attributes: line_item_params }
                    test_params = default_params.merge(id: donation.id, donation: donation_params)
                    expect do
                        put donation_path test_params
                    end.to raise_error(Errors::InsufficientAllotment)

                    expect(original_storage_location.size).to eq 5
                    expect(new_storage_location.size).to eq 0
                    expect(donation.reload.line_items.first.quantity).to eq 10
                end
            end

            describe "when removing a line item" do
                it "updates storage invetory item quantity correctly" do
                    donation = create(:donation, :with_items, item_quantity: 10)
                    line_item = donation.line_items.first
                    line_item_params = {
                        "0" => {
                        "_destroy" => "true",
                        item_id: line_item.item_id,
                        id: line_item.id
                        }
                    }
                    donation_params = { source: donation.source, line_items_attributes: line_item_params }
                    test_params = default_params.merge(id: donation.id, donation: donation_params)
                    expect do
                        put donation_path test_params
                    end.to change { donation.storage_location.inventory_items.first.quantity }.by(-10)
                end

                it "deletes inventory item if line item and inventory item quantities are equal" do
                    donation = create(:donation, :with_items, item_quantity: 1)
                    line_item = donation.line_items.first
                    inventory_item = donation.storage_location.inventory_items.first
                    inventory_item.update(quantity: line_item.quantity)
                    line_item_params = {
                        "0" => {
                        "_destroy" => "true",
                        item_id: line_item.item_id,
                        id: line_item.id
                        }
                    }
                    donation_params = { source: donation.source, line_items_attributes: line_item_params }
                    test_params = default_params.merge(id: donation.id, donation: donation_params)

                    put donation_path test_params
                    expect { inventory_item.reload }.to raise_error(ActiveRecord::RecordNotFound)
                end
            end
        end # End of PUT #update block

        describe "GET #edit" do

            it "returns http success" do
                params = default_params.merge(id: donation.id)
                get edit_donation_path params
                expect(response).to be_successful
                expect(response).to render_template(:edit)
            end
        end

        describe "GET #show" do
            it "returns http success" do
                params = default_params.merge(id: donation.id)
                get donation_path params
                expect(response).to be_successful
                expect(response).to render_template(:show)
            end
        end

        describe "DELETE #destroy" do
            # normal users are not authorized

            it "redirects to the dashboard path" do
                params = default_params.merge(id: donation.id)
                delete donation_path params
                expect(response).to redirect_to(dashboard_path)
            end
        end

        context "Looking at a different organization" do
            let(:object) { create(:donation, organization: create(:organization)) }

            include_examples "requiring authorization"

            it "Disallows all access for Donation-specific actions" do
                single_params = { organization_id: object.organization.to_param, id: object.id }

                patch add_item_donation_path(single_params)
                expect(response).to have_http_status(302)
                expect(response).to be_redirect

                patch remove_item_donation_path(single_params)
                expect(response).to have_http_status(302)
                expect(response).to be_redirect
            end
        end 

        context "While signed in as an organization admin >" do
            before do
                sign_in(@organization_admin)
            end

            describe "DELETE #destroy" do
                it "redirects to the index" do
                    params = default_params.merge(id: donation.id)
                    delete donation_path(params)
                    expect(response).to redirect_to(donations_path)
                end
            end
        end

        context "While not signed in" do
            let(:object) { create(:donation) }

            include_examples "requiring authorization"

            it "redirects the user to the sign-in page for Donation specific actions" do
                single_params = { organization_id: object.organization.to_param, id: object.id }

                patch add_item_donation_path(single_params)
                expect(response).to have_http_status(200)

                patch remove_item_donation_path(single_params)
                expect(response).to have_http_status(200)
            end
        end

    end
end