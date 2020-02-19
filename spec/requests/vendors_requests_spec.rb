RSpec.describe "Vendors", type: :request do
  let(:default_params) do
    { organization_id: @organization.to_param }
  end

  context "While signed in" do
    before do
      sign_in(@user)
    end

    describe "GET #index" do
      it "returns http success" do
        get vendors_path(default_params)
        expect(response).to be_successful
      end
    end

    describe "GET #new" do
      it "returns http success" do
        get new_vendor_path(default_params)
        expect(response).to be_successful
      end
    end

    describe "GET #edit" do
      it "returns http success" do
        get edit_vendor_path(default_params.merge(id: create(:vendor, organization: @user.organization)))
        expect(response).to be_successful
      end
    end

    describe "POST #import_csv" do
      let(:model_class) { Vendor }

      context "with a csv file" do
        let(:file) { fixture_file_upload("#{model_class.name.underscore.pluralize}.csv", "text/csv") }
        subject { post import_csv_vendors_path(default_params), params: { file: file } }

        it "invokes .import_csv" do
          expect(model_class).to respond_to(:import_csv).with(2).arguments
        end

        it "redirects" do
          subject
          expect(response).to be_redirect
        end

        it "presents a flash notice message" do
          subject
          expect(response).to have_notice "#{model_class.name.underscore.humanize.pluralize} were imported successfully!"
        end
      end

      context "without a csv file" do
        subject { post import_csv_vendors_path(default_params) }

        it "redirects to :index" do
          subject
          expect(response).to be_redirect
        end

        it "presents a flash error message" do
          subject
          expect(response).to have_error "No file was attached!"
        end
      end

      context "csv file with wrong headers" do
        let(:file) { fixture_file_upload("wrong_headers.csv", "text/csv") }
        subject { post import_csv_vendors_path(default_params), params: { file: file } }

        it "redirects" do
          subject
          expect(response).to be_redirect
        end

        it "presents a flash error message" do
          subject
          expect(response).to have_error "Check headers in file!"
        end
      end
    end

    describe "GET #show" do
      it "returns http success" do
        get vendor_path(default_params.merge(id: create(:vendor, organization: @organization)))
        expect(response).to be_successful
      end
    end

    describe "DELETE #destroy" do
      subject { delete vendor_path(default_params.merge(id: create(:vendor))) }
      it "does not have a route for this" do
        expect { subject }.to raise_error(ActionController::RoutingError)
      end
    end

    describe "XHR #create" do
      it "successful create" do
        post vendors_path(default_params.merge(vendor: { name: "test", email: "123@mail.ru" }))
        expect(response).to be_successful
      end

      it "flash error" do
        post vendors_path(default_params.merge(vendor: { name: "test" }))
        expect(response).to be_successful
        expect(response).to have_error(/try again/i)
      end
    end

    describe "POST #create" do
      it "successful create" do
        post vendors_path(default_params.merge(vendor: { business_name: "businesstest", contact_name: "test", email: "123@mail.ru" }))
        expect(response).to redirect_to(vendors_path)
        expect(response).to have_notice(/added!/i)
      end

      it "flash error" do
        post vendors_path(default_params.merge(vendor: { name: "test" }, xhr: true))
        expect(response).to be_successful
        expect(response).to have_error(/try again/i)
      end
    end

    context "Looking at a different organization" do
      let(:object) { create(:vendor, organization: create(:organization)) }
      include_examples "requiring authorization"
    end
  end

  context "While not signed in" do
    let(:object) { create(:vendor) }

    include_examples "requiring authorization"
  end
end
