RSpec.describe "ProductDriveParticipants", type: :request do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }

  context "While signed in" do
    before do
      sign_in(user)
    end

    describe "GET #index" do
      subject do
        get product_drive_participants_path(format: response_format)
        response
      end

      before { create(:product_drive_participant) }

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
        get new_product_drive_participant_path
        expect(response).to be_successful
      end
    end

    describe "GET #edit" do
      it "returns http success" do
        get edit_product_drive_participant_path(id: create(:product_drive_participant, organization: user.organization))
        expect(response).to be_successful
      end
    end

    describe "POST #import_csv" do
      let(:model_class) { ProductDriveParticipant }

      context "with a csv file" do
        let(:file) { fixture_file_upload("#{model_class.name.underscore.pluralize}.csv", "text/csv") }
        subject { post import_csv_product_drive_participants_path, params: { file: file } }

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
        subject { post import_csv_product_drive_participants_path }

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
        subject { post import_csv_product_drive_participants_path, params: { file: file } }

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
      it "returns http success and displays comments" do
        comment = "Test comment about product drive participant."
        @participant = create(:product_drive_participant, organization: organization, comment: comment)
        get product_drive_participant_path(id: @participant)
        expect(response).to be_successful
        expect(response.body).to include(comment)
      end
    end

    describe "XHR #create" do
      it "successful create" do
        post product_drive_participants_path(product_drive_participant: { name: "test", email: "123@mail.ru" }, xhr: true)
        expect(response).to be_successful
      end

      it "flash error" do
        post product_drive_participants_path(product_drive_participant: { name: "test" }, xhr: true)
        expect(response).to be_successful
        expect(response).to have_error(/try again/i)
      end
    end

    describe "POST #create" do
      it "successful create" do
        post product_drive_participants_path(product_drive_participant:
          { business_name: "businesstest", contact_name: "test", email: "123@mail.ru" })
        expect(response).to redirect_to(product_drive_participants_path)
        expect(response).to have_notice(/added!/i)
      end

      it "flash error" do
        post product_drive_participants_path(product_drive_participant: { name: "test" }, xhr: true)
        expect(response).to be_successful
        expect(response).to have_error(/try again/i)
      end
    end

    context "Looking at a different organization" do
      let(:object) { create(:product_drive_participant, organization: create(:organization)) }
      include_examples "requiring authorization"
    end
  end

  context "While not signed in" do
    let(:object) { create(:product_drive_participant) }

    include_examples "requiring authorization"
  end
end
