namespace :bank_listings do
  desc "Refresh the bank finder's listings from the NDBN and Alliance for Period Supplies directories"
  task import: :environment do
    result = BankListingImportService.call
    abort "Kept the existing list: #{result.error}" unless result.success?
    puts "Imported #{result.imported} banks."
    puts "Could not place #{result.unplaced.size}: #{result.unplaced.join("; ")}" if result.unplaced.any?
  end
end
