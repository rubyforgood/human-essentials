module Exports
  class ExportProductDrivesCSVService
    extend ItemsHelper
    HEADERS = ['Product Drive Name','Start Date','End Date','Held Virtually?','Quantity of Items','Variety of Items','In Kind Value']

    def self.generate_csv(product_drives)
      CSV.generate do |csv|
        csv << HEADERS

        product_drives.each do |drive|
          csv << generate_row(drive)
        end
      end
    end

    private
    
    def self.generate_row(drive)
      [ 
        "#{drive.name}", 
        "#{drive.start_date.strftime("%m-%d-%Y")}", 
        "#{drive.end_date&.strftime("%m-%d-%Y")}", 
        "#{drive.virtual ? 'Yes' : 'No'}", 
        "#{drive.donation_quantity}",
        "#{drive.distinct_items_count}",
        "#{dollar_value(drive.in_kind_value)}"
      ]
    end
  end
end
