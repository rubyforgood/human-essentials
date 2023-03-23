module ImportCSVTextHelper
  IMPORT_TEXT = 'Then click the "Import CSV" button to import your'

  def import_csv_custom_text(csv_template_url, csv_import_url = nil)
    return "#{IMPORT_TEXT} product drive participants." if csv_template_url == "/product_drive_participants.csv"
    return "#{IMPORT_TEXT} storage locations." if csv_template_url == "/storage_locations.csv"
    return "#{IMPORT_TEXT} donation sites." if csv_template_url == "/donation_sites.csv"
    return "#{IMPORT_TEXT} partners." if csv_template_url == "/partners.csv"
    return "#{IMPORT_TEXT} storage locations." if csv_template_url == "/diaper_bank/storage_locations/#{csv_import_url[-1]}.csv"
    "#{IMPORT_TEXT} vendors." if csv_template_url == "/vendors.csv"
  end
end
