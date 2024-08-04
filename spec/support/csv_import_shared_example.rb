RSpec.shared_examples "csv import" do
  context "with a csv file" do
    let(:file) { Rack::Test::UploadedFile.new "spec/fixtures/files/#{model_class.name.underscore.pluralize}.csv", "text/csv" }
    subject { post :import_csv, params: {file: file} }

    it "invokes .import_csv" do
      expect(model_class).to respond_to(:import_csv).with(2).arguments
    end

    it "redirects to :index" do
      expect(subject).to be_redirect
    end

    it "presents a flash notice message" do
      expect(subject).to have_notice "#{model_class.name.underscore.humanize.pluralize} were imported successfully!"
    end
  end

  context "without a csv file" do
    subject { post :import_csv }

    it "redirects to :index" do
      expect(subject).to be_redirect
    end

    it "presents a flash error message" do
      expect(subject).to have_error "No file was attached!"
    end
  end

  context "csv file with wrong headers" do
    let(:file) { Rack::Test::UploadedFile.new "spec/fixtures/files/wrong_headers.csv", "text/csv" }
    subject { post :import_csv, params: {file: file} }

    it "redirects to :index" do
      expect(subject).to be_redirect
    end

    it "presents a flash error message" do
      expect(subject).to have_error "Check headers in file!"
    end
  end
end
