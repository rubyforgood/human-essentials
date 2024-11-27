shared_examples_for "provideable" do
  let(:model_f) { described_class.to_s.underscore.to_sym }

  context "Validations" do
    it "is invalid unless it has either a contact name or a business name" do
      expect(build(model_f, contact_name: nil, business_name: nil)).not_to be_valid
      expect(build(model_f, contact_name: nil, business_name: "George Company").valid?).to eq(true)
      expect(build(model_f, contact_name: "George Henry").valid?).to eq(true)
    end

    it "is invalid without an organization" do
      expect(build(model_f, organization: nil)).not_to be_valid
    end
  end

  describe "geocode" do
    it "adds coordinates to the database" do
      ddp = build(model_f,
                  "address" => "123 Donation Site Way")
      ddp.save
      expect(ddp.latitude).not_to eq(nil)
      expect(ddp.longitude).not_to eq(nil)
    end
  end

  describe "import_csv" do
    it "imports from a csv file" do
      before_import = described_class.count
      organization = create(:organization)
      import_file_path = Rails.root.join("spec", "fixtures", "files", "#{described_class.to_s.split(/(?=[A-Z])/).join("_").downcase}s.csv")
      data = File.read(import_file_path, encoding: "BOM|UTF-8")
      csv = CSV.parse(data, headers: true)
      described_class.import_csv(csv, organization.id)
      expect(described_class.count).to eq before_import + 3
    end
  end
end
