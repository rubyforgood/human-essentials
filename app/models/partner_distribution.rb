class PartnerDistribution
  include Exportable

  def self.for_csv_export(organization, filters, *)
    Distribution.includes(:partner, :storage_location, :line_items)
                .where(organization: organization, partner_id: filters[:partner_id])
  end

  def self.csv_export(distributions)
    headers = ["Date", "Source Inventory", "Total Items"]
    [headers, *rows(distributions, headers)]
  end

  def self.rows(distributions, headers)
    distributions.map do |distribution|
      {
        "Date" => distribution.issued_at.strftime("%m/%d/%Y"),
        "Source Inventory" => distribution.storage_location.name,
        "Total Items" => distribution.line_items.total
      }.tap do |row|
        distribution.line_items.quantities_by_name.each do |_id, item_ref|
          row[item_ref[:name]] = item_ref[:quantity]
          headers << item_ref[:name] unless headers.include?(item_ref[:name])
        end
      end
    end
  end
end
