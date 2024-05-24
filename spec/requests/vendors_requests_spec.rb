RSpec.describe "Vendors", type: :request do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }

  context "While signed in" do
    before do
      sign_in(user)
    end

    describe "GET #index" do
      subject do
        get vendors_path(format: response_format)
        response
      end

      before { create(:vendor) }

      context "html" do
        let(:response_format) { 'html' }

        it { is_expected.to be_successful }
      end

      context "csv" do
        let(:response_format) { 'csv' }

        it { is_expected.to be_successful }
      end
    end

    describe "GET #new" do
      it "returns http success" do
        get new_vendor_path
        expect(response).to be_successful
      end
    end

    describe "GET #edit" do
      it "returns http success" do
        get edit_vendor_path(id: create(:vendor, organization: user.organization))
        expect(response).to be_successful
      end
    end

    describe "POST #import_csv" do
      let(:model_class) { Vendor }

      context "with a csv file" do
        let(:file) { fixture_file_upload("#{model_class.name.underscore.pluralize}.csv", "text/csv") }
        subject { post import_csv_vendors_path, params: { file: file } }

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
        subject { post import_csv_vendors_path }

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
        subject { post import_csv_vendors_path, params: { file: file } }

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
        get vendor_path(id: create(:vendor, organization: organization))
        expect(response).to be_successful
      end
    end

    describe "DELETE #destroy" do
      subject { delete vendor_path(id: create(:vendor)) }
      it "does not have a route for this" do
        expect { subject }.to raise_error(ActionController::RoutingError)
      end
    end

    describe "XHR #create" do
      it "successful create" do
        post vendors_path(vendor: { name: "test", email: "123@mail.ru" })
        expect(response).to be_successful
      end

      it "flash error" do
        post vendors_path(vendor: { name: "test" })
        expect(response).to be_successful
        expect(response).to have_error(/try again/i)
      end
    end

    describe "POST #create" do
      it "successful create" do
        post vendors_path(vendor: { business_name: "businesstest", contact_name: "test", email: "123@mail.ru" })
        expect(response).to redirect_to(vendors_path)
        expect(response).to have_notice(/added!/i)
      end

      it "flash error" do
        post vendors_path(vendor: { name: "test" }, xhr: true)
        expect(response).to be_successful
        expect(response).to have_error(/try again/i)
      end
    end

    context "Looking at a different organization" do
      let(:object) { create(:vendor, organization: create(:organization)) }
      include_examples "requiring authorization"
    end

    describe "when on vendors index page" do
      it "has the correct import type" do
        get vendors_path(format: 'html')

        expect(response.body).to include('Import Vendors')
      end
    end
  end

  context "While not signed in" do
    let(:object) { create(:vendor) }

    include_examples "requiring authorization"
  end
end
