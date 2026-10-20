RSpec.describe BankListingImportJob do
  it "emails super admins when the import keeps last week's list" do
    create(:super_admin, email: "admin@example.com")
    failed = BankListingImportService::Result.new(imported: 0, unplaced: [], error: "The diapers directory had no banks in it.")
    allow(BankListingImportService).to receive(:call).and_return(failed)

    expect { described_class.perform_now }.to have_enqueued_mail(BankListingMailer, :import_failed)
      .with(error: "The diapers directory had no banks in it.")
  end

  it "emails nobody when the import succeeds" do
    allow(BankListingImportService).to receive(:call)
      .and_return(BankListingImportService::Result.new(imported: 7, unplaced: [], error: nil))

    expect { described_class.perform_now }.not_to have_enqueued_mail(BankListingMailer, :import_failed)
  end
end
