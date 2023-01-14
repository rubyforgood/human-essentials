RSpec.describe OrganizationsController, type: :controller do
  let(:default_params) do
    { organization_id: @organization.to_param }
  end

  context "While signed in as org admin" do
    before do
      sign_in(@organization_admin)
    end
    
    describe "POST #update" do
      context "When all distribution types are disabled" do
        subject { put :update, params: default_params.merge( 
          enable_child_based_requests: false, 
          enable_individual_requests: false, 
          enable_quantity_based_requests: false )
        }

        it "Returns flash error indicating at least one distribuion type must be selected" do
          expect(flash[:error]).to eq("enable_requests: You must allow at least one request type (child-based, individual, or quantity-based)")
        end
      end
    end
  end
end

