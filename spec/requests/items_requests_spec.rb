require 'rails_helper'

RSpec.describe "Items", type: :request do
    let(:default_params) do
        { organization_id: @organization.to_param }
    end
    
    context "While signed in" do
        before do
            sign_in(@user)
        end

        describe "GET #index" do
            
            it "returns http success" do
                get items_path(default_params)
                expect(response).to be_successful
                expect(response).to render_template(:index)
            end
        end

        describe "GET #new" do

            it "returns http success" do
                get new_item_path(default_params)
                expect(response).to be_successful
                expect(response).to render_template(:new)
            end
        end

        describe "GET #edit" do

            it "returns http success" do
                test_params = default_params.merge(id: create(:item, organization: @organization))
                get edit_item_path(test_params)
                expect(response).to be_successful
                expect(response).to render_template(:edit)
            end
        end

        describe "GET #show" do

            it "returns http success" do
                test_params = default_params.merge(id: create(:item, organization: @organization))
                get item_path(test_params)
                expect(response).to be_successful
                expect(response).to render_template(:show)
            end
        end

        describe "DELETE #destroy" do
            
            it "redirects to #index" do
                test_params = default_params.merge(id: create(:item, organization: @organization))
                delete item_path(test_params)
                expect(response).to have_http_status(302)
                expect(subject).to redirect_to(items_path)
            end
        end

        describe "PATCH #restore" do

            context "with a soft-deleted item" do
                let!(:item) { create(:item, :inactive) }

                it "re-activates the item" do
                    expect do
                        params = default_params.merge(id: item.id)
                        patch restore_item_path(params)
                    end.to change { Item.active.size }.by(1)
                end
            end

        end

        context "with an active item" do
            let!(:item) { create(:item, :active) }

            it "does nothing" do
                expect do
                    params = default_params.merge(id: item.id)
                    patch restore_item_path(params)
                end.to change { Item.active.size }.by(0)
            end
        end

        context "with another organizations item" do
            let!(:external_item) { create(:item, :inactive, organization: create(:organization)) }
            
            it "does nothing" do
                expect do
                    params = default_params.merge(id: external_item.id)
                    patch restore_item_path(params)
                end.to change { Item.active.size }.by(0)
            end
        end
    end # End of PATCH block

    describe "POST #create" do
        context "with valid params" do

            let!(:item_params) do
                {
                    item: {
                        name: "Really Good Item",
                        partner_key: create(:base_item).partner_key,
                        value_in_cents: 1001,
                        package_size: 5,
                        distribution_quantity: 30,
                        on_hand_minimum_quantity: 15,
                        on_hand_recommended_quantity: 10
                    }
                }
            end

            it "should accept params with dollar signs, periods, and commas" do
                item_params["value_in_cents"] = "$5,432.10"
                params = default_params.merge(item_params)
                post items_path(params)
                expect(response).not_to have_error
            end
        end

        context "Looking at a different organization" do
            let(:object) { create(:item, organization: create(:organization)) }
            include_examples "requiring authorization"
        end
    end  # End of POST create block

    context "While not signed in" do
        let(:object) { create(:item) }

        include_examples "requiring authorization"
    end
end