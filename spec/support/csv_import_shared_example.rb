RSpec.shared_examples "csv import" do
  context "with a csv file" do
    let(:file) { Rack::Test::UploadedFile.new "spec/fixtures/#{model_class.name.underscore.pluralize}.csv", "text/csv" }
    subject { post :import_csv, params: default_params.merge(file: file) }

    it "invokes .import_csv" do
      expect(model_class).to respond_to(:import_csv).with(2).arguments
    end

    it "redirects to :index" do
      expect(subject).to be_redirect
    end

    it "presents a flash notice message" do
      expect(subject.request.flash[:notice]).to eq "#{model_class.name.underscore.humanize.pluralize} were imported successfully!"
    end
  end

  context "without a csv file" do
    subject { post :import_csv, params: default_params }

    it "redirects to :index" do
      expect(subject).to be_redirect
    end

    it "presents a flash error message" do
      expect(subject.request.flash[:error]).to eq "No file was attached!"
    end
  end
end
