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
        let!(:no_purchases_vendor) { create(:vendor, business_name: "Abc", organization: organization) }
        let(:purchase_vendor) { create(:vendor, business_name: "Xyz", organization: organization) }
        let!(:deactivated_vendor) { create(:vendor, business_name: "Deactivated", organization: organization, active: false) }

        let(:response_format) { 'html' }

        it { is_expected.to be_successful }

        before do
          create(:purchase, :with_items, vendor: purchase_vendor)
        end

        it "should have only activated vendor names" do
          subject
          expect(response.body).to include(no_purchases_vendor.business_name)
          expect(response.body).not_to include(deactivated_vendor.business_name)
        end

        it "should have a delete button for no_purchases_vendor and a deactivate button for purchase_vendor" do
          subject
          parsed_body = Nokogiri::HTML(response.body)
          no_purchases_vendor_row = parsed_body.css("tr").find { |row| row.text.include?(no_purchases_vendor.business_name) }
          purchase_vendor_row = parsed_body.css("tr").find { |row| row.text.include?(purchase_vendor.business_name) }

          expect(no_purchases_vendor_row.at_css("a", text: "Delete")).to be_present
          expect(purchase_vendor_row.at_css("a", text: "Deactivate")).to be_present
        end
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

      it "displays purchases in reverse chronological order by issued_at date" do
        vendor = create(:vendor, organization: organization)

        # Create purchases with different issued_at dates
        old_purchase = create(:purchase, vendor: vendor, issued_at: 1.week.ago, organization: organization)
        new_purchase = create(:purchase, vendor: vendor, issued_at: 1.day.ago, organization: organization)
        middle_purchase = create(:purchase, vendor: vendor, issued_at: 3.days.ago, organization: organization)

        get vendor_path(vendor)

        expect(vendor.reload.purchases.order(issued_at: :desc).to_a).to eq([new_purchase, middle_purchase, old_purchase])
        expect(response).to be_successful
      end
    end

    describe "DELETE #destroy" do
      let!(:vendor) { create(:vendor, organization: organization) }

      subject { delete vendor_path(id: vendor.id) }

      context 'when vendor does not have purchase items' do
        it 'shoud delete the vendor' do
          expect { subject }.to change(Vendor, :count)
          expect(response).to redirect_to(vendors_path)
          follow_redirect!
          expect(response.body).to include("#{vendor.business_name} has been removed.")
        end
      end

      context 'when vendor has purchase items' do
        before do
          create(:purchase, :with_items, vendor: vendor)
        end

        it 'shoud not delete the vendor' do
          expect { subject }.not_to change(Vendor, :count)
          expect(response).to have_error(/ could not be removed/)
        end
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
