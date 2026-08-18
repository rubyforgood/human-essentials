# The reports hub, as data.
#
# Eleven reports, grouped by subject. Each carries a short qualifier rather than a sentence:
# a hub is a menu, and a sentence per entry turns a menu into reading. The qualifier says the
# thing you are choosing between -- how the data is cut -- in two to four words.
#
# There is no "summary" report for distributions, donations, purchases or product drives. Those
# pages were weaker copies of the index pages, which have more filters, the full table and the
# same totals; their figures now sit at the top of the index instead. What remains here is the
# eleven reports an index page genuinely cannot show.
module ReportsCatalogHelper
  Report = Data.define(:label, :path, :qualifier)
  ReportSection = Data.define(:label, :icon, :reports)

  def reports_catalog
    [
      ReportSection.new(
        label: "Distributions", icon: "bi-truck",
        reports: [
          Report.new(label: "Itemized", path: reports_itemized_distributions_path,
            qualifier: "by item and partner"),
          Report.new(label: "Trends", path: historical_trends_distributions_path,
            qualifier: "12 months, chart"),
          Report.new(label: "By county", path: distributions_by_county_report_path(filters: {date_range: date_range_params}),
            qualifier: "geographic totals")
        ]
      ),
      ReportSection.new(
        label: "Donations", icon: "bi-gift",
        reports: [
          Report.new(label: "Itemized", path: reports_itemized_donations_path,
            qualifier: "by item"),
          Report.new(label: "Trends", path: historical_trends_donations_path,
            qualifier: "12 months, chart"),
          Report.new(label: "From manufacturers", path: reports_manufacturer_donations_summary_path,
            qualifier: "manufacturer sourced only")
        ]
      ),
      ReportSection.new(
        label: "Purchases", icon: "bi-cart",
        reports: [
          Report.new(label: "Trends", path: historical_trends_purchases_path,
            qualifier: "12 months, chart")
        ]
      ),
      ReportSection.new(
        label: "Requests", icon: "bi-clipboard-check",
        reports: [
          Report.new(label: "Itemized", path: reports_itemized_requests_path,
            qualifier: "by item")
        ]
      ),
      ReportSection.new(
        label: "Compliance", icon: "bi-file-earmark-text",
        reports: [
          Report.new(label: "Annual survey", path: reports_annual_reports_path,
            qualifier: "one page per year")
        ]
      ),
      ReportSection.new(
        label: "Activity", icon: "bi-clock-history",
        reports: [
          Report.new(label: "Activity graph", path: reports_activity_graph_path,
            qualifier: "received against distributed"),
          Report.new(label: "History", path: events_path,
            qualifier: "inventory event log")
        ]
      )
    ]
  end

  def reports_catalog_count = reports_catalog.sum { |section| section.reports.size }
end
