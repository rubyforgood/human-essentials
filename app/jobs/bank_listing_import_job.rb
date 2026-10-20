# Refreshes the bank finder's listings from the NDBN and Alliance for Period Supplies directories.
# Weekly, from clock.rb. When the import refuses to replace the list -- a directory would not
# download, or came back far smaller than last week -- the old list stays and super admins are
# emailed, so a moved map is noticed by a person rather than by a visitor. See ADR 0014.
class BankListingImportJob < ApplicationJob
  def perform
    result = BankListingImportService.call
    if result.success?
      Rails.logger.info("[BankListingImportJob] #{result.imported} listings, #{result.unplaced.size} not placed")
      Rails.logger.warn("[BankListingImportJob] not placed: #{result.unplaced.join("; ")}") if result.unplaced.any?
    else
      BankListingMailer.import_failed(error: result.error).deliver_later
    end
  end
end
