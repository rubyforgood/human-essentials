RSpec.describe PartnersController, type: :controller do
  let(:default_params) do
    { organization_id: @organization.to_param }
  end

  context "While signed in" do
    before do
      sign_in(@user)
    end
    
    describe "PUT #deactivate" do
      let(:partner) { create(:partner, organization: @organization) }
      
      context "when the partner successfully deactivates" do
        it "sets the status of a partner to deactivated and redirects to partners_path" do
          expect(partner.status).not_to eq("deactivated")

          put :deactivate, params: default_params.merge(id: partner.id)

          expect(partner.reload.status).to eq("deactivated")
          expect(response).to redirect_to(partners_path)
          expect(flash[:notice]).to eq("#{partner.name} successfully deactivated!")
        end      
      end

      context "when the partner does not successfully deactivate" do
        before do
          allow_any_instance_of(Partner).to receive(:save).and_return(false)
        end

        it "provides an error message if the partner fails to deactivate and redirects to partners_path" do
          put :deactivate, params: default_params.merge(id: partner.id)
          expect(partner.reload.status).not_to eq("deactivated")
          expect(response).to redirect_to(partners_path)
          expect(flash[:error]).to eq("#{partner.name} failed to deactivate!")
        end      
      end

    end
  end
end
