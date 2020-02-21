require 'rails_helper'

RSpec.describe "Organizations", type: :request do
    let(:default_params) do
        { organization_id: @organization.to_param }
    end

    context "While signed in as a normal user" do
        before do
          sign_in(@user)
        end
    
        describe "GET #show" do

          it "is successful" do
            get organization_path(default_params)
            expect(response).to be_successful
            expect(response).to render_template(:show)
          end
        end
    
        describe "GET #edit" do    
          it "denies access and redirects with an error" do
            get edit_organization_path(default_params)

            expect(response).to have_http_status(:redirect)
            expect(response).to have_error
            
          end
        end
    end
    
    context "While signed in as an organization admin" do
        before do
            sign_in(@organization_admin)
        end

        describe "GET #edit" do    
            it "is successful" do
                get edit_organization_path(default_params)
                expect(response).to be_successful
                expect(response).to render_template(:edit)
            end
        end

        describe "POST #promote_to_org_admin" do
            it "promotes the user to organization admin" do
                test_params = default_params.merge(user_id: @user.id) 
                post promote_to_org_admin_organization_path(test_params)
                expect(response).to have_http_status(:redirect)
                expect(response).to have_http_status(302)

                @user.reload
                expect(@user.kind).to eq("admin")
            end
        end

        context "when attempting to access a different organization" do
            let(:other_organization) { create(:organization) }

            let(:other_organization_params) do
                { organization_id: other_organization.to_param }
            end

            describe "GET #show" do

                it "redirects to dashboard" do
                    get organization_path(other_organization_params)
                    expect(response).to redirect_to(dashboard_path)
                end
            end

            describe "GET #edit" do    
                it "redirects to dashboard" do
                    get edit_organization_path(other_organization_params)  
                    expect(response).to redirect_to(dashboard_path)
                end
            end

            describe "POST #promote_to_org_admin" do
                let(:other_user) { create(:user, organization: other_organization) }

                it "does not promote user" do
                    test_params = default_params.merge(user_id: other_user.id)
                    post promote_to_org_admin_organization_path(test_params)
                    expect(response).to have_http_status(:not_found)

                    other_user.reload
                    expect(other_user.kind).to eq("normal")
                end
            end
        end
    end
end