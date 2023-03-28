RSpec.describe "Vendors", type: :view do
  context "when rendering the import modal" do
    it "renders the correct modal title" do
      render(
        partial: "shared/csv_import_modal",
        locals: {
          import_type: "Vendors",
          csv_template_url: "/vendors.csv",
          csv_import_url: "import_csv_vendors_path"
        }
      )

      expect(response).to have_text("Import Vendors")
    end
  end
end
