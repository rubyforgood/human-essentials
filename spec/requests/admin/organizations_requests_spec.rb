RSpec.describe "Admin::Organizations", type: :request do
  let(:default_params) do
    { organization_id: @organization.id }
  end

  context "When logged in as a super admin" do
    before do
      sign_in(@super_admin)
    end

    describe "GET #new" do
      it "returns http success" do
        get new_admin_organization_path
        expect(response).to be_successful
      end

      context 'when given a valid account request token in the query parameters' do
        let!(:account_request) { FactoryBot.create(:account_request) }

        it 'should render new with pre populate input fields from the account_request' do
          get new_admin_organization_url(token: account_request.identity_token)
          expect(response).to render_template(:new)

          # Just checking if the values appear in the template. This assumes
          # that if they are present in the body then they are pre-populating
          # the form. A system test will likely handle this test case.
          #
          # Using CGI.escapeHTML to match account_request attribute which is rendered
          # to be HTML safe. If the organization_name or any attribute has unsafe characters
          # then this test would fail. For example, if the organization_name were
          # "Pouros, O'Kon and Schumm"
          #
          # rubocop:disable Style/ColonMethodCall
          expect(response.body).to match(CGI::escapeHTML(account_request.name))
          expect(response.body).to match(CGI::escapeHTML(account_request.email))
          expect(response.body).to match(CGI::escapeHTML(account_request.organization_name))
          expect(response.body).to match(CGI::escapeHTML(account_request.organization_website))
          # rubocop:enable Style/ColonMethodCall
        end
      end

      context 'when given a token that matches a account request that has already been processed' do
        let!(:account_request) { FactoryBot.create(:account_request) }

        before do
          FactoryBot.create(:organization, account_request_id: account_request.id)
        end

        it 'should render new with a flash error message' do
          get new_admin_organization_url(token: account_request.identity_token)
          expect(response).to render_template(:new)

          expect(response.body).to include("The account request had already been processed and cannot be used again")
        end
      end
    end

    xdescribe "POST #create" do
      let(:valid_organization_params) { attributes_for(:organization, users_attributes: [attributes_for(:organization_admin)]) }

      context "with valid params" do
        it "redirects to #index" do
          post admin_organizations_path({ organization: valid_organization_params })

          expect(response).to redirect_to(admin_organizations_path)
        end
      end

      context "with invalid params" do
        let(:invalid_params) { valid_organization_params.merge(name: nil) }

        it "renders #create with an error message" do
          post admin_organizations_path({ organization: invalid_params })

          expect(subject).to render_template("new")
          expect(flash[:error]).to be_present
        end
      end
    end

    describe "GET #index" do
      it "returns http success" do
        get admin_organizations_path
        expect(response).to be_successful
      end
    end

    describe "PATCH #update" do
      let(:organization) { create(:organization, name: "Original Name") }
      subject do
        patch admin_organization_path(default_params.merge(id: organization.id, organization: { name: updated_name }))
      end

      context "with a valid update" do
        let(:updated_name) { "Updated Name" }
        let(:redirect_status) { 302 }

        it "redirects to #index" do
          expect(subject).to be(redirect_status)
          expect(subject).to redirect_to(admin_organizations_path({ organization_id: @organization }))
        end
      end

      context "with an invalid update" do
        let(:updated_name) { nil }
        let(:successful) { 200 }

        subject do
          patch admin_organization_path(default_params.merge(id: organization.id, organization: { name: updated_name }))
        end

        it "returns http success" do
          expect(subject).to be(successful)
        end

        it "redirects to #edit with an error message" do
          expect(subject).to render_template("edit")
          expect(flash[:error]).to be_present
        end
      end
    end

    describe "DELETE #destroy" do
      let(:organization) { create(:organization) }

      context "with a valid organization id" do
        it "redirects to #index" do
          delete admin_organization_path({ id: organization.id })
          expect(response).to redirect_to(admin_organizations_path({ organization_id: @organization }))
        end
      end
    end

    describe "GET #edit" do
      let!(:organization) { create(:organization) }

      it "returns http success" do
        get edit_admin_organization_path({ id: organization.id })
        expect(response).to be_successful
      end
    end

    describe "GET #show" do
      let!(:organization) { create(:organization) }

      it "returns http success" do
        get admin_organization_path({ id: organization.id })
        expect(response).to be_successful
      end
    end

    describe "PUT #update" do
      it "redirect" do
        put admin_organization_path({ id: @organization.id, organization: { name: "Foo" } })
        expect(response).to be_redirect
      end
    end

    describe "DELETE #destroy" do
      it "redirects" do
        delete admin_organization_path({ id: @organization.id })
        expect(response).to redirect_to(admin_organizations_path({ organization_id: @organization }))
      end
    end
  end

  context "When logged in as a non-admin user" do
    before do
      sign_in(@user)
    end

    describe "GET #new" do
      it "redirects" do
        get new_admin_organization_path
        expect(response).to be_redirect
      end
    end

    describe "POST #create" do
      it "redirects" do
        post admin_organizations_path({ organization: attributes_for(:organization) })
        expect(response).to be_redirect
      end
    end

    describe "GET #index" do
      it "redirects" do
        get admin_organizations_path
        expect(response).to be_redirect
      end
    end

    describe "GET #edit" do
      it "redirects" do
        get edit_admin_organization_path({ id: @organization.id })
        expect(response).to be_redirect
      end
    end

    describe "PUT #update" do
      it "redirects" do
        put admin_organization_path({ id: @organization.id, organization: { name: "Foo" } })
        expect(response).to be_redirect
      end
    end
  end
end
