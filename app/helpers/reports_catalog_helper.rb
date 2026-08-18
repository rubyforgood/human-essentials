# The reports hub, as data.
#
# Fifteen reports used to sit in one sidebar group, where the other three groups hold five,
# seven and seven. Twelve of the fifteen are a sparse subject-by-cut grid -- distributions,
# donations, purchases, product drives and requests, each cut as a summary, an itemised
# breakdown or a twelve-month trend -- which a flat list cannot express. The labels compensated
# by encoding the grid in the string ("Distributions — summary") so that they at least sorted
# together.
#
# Here the grid is the layout, so a report is named for its cut and grouped under its subject.
# Descriptions are read off the controller actions, not invented: each says what the page
# actually loads.
module ReportsCatalogHelper
  Report = Data.define(:label, :path, :description)
  ReportSection = Data.define(:label, :icon, :description, :reports)

  def reports_catalog
    [
      ReportSection.new(
        label: "Distributions", icon: "bi-truck",
        description: "What you sent to partner agencies.",
        reports: [
          Report.new(label: "Summary", path: reports_distributions_summary_path,
            description: "Every distribution in the date range, newest first, with its partner."),
          Report.new(label: "Itemized", path: reports_itemized_distributions_path,
            description: "How much of each item went out, broken down by partner."),
          Report.new(label: "Trends", path: historical_trends_distributions_path,
            description: "The last twelve months as a chart. Cached, so up to a day behind."),
          Report.new(label: "By county", path: distributions_by_county_report_path(filters: {date_range: date_range_params}),
            description: "Totals for the counties your partners serve, for funders who ask geographically.")
        ]
      ),
      ReportSection.new(
        label: "Donations", icon: "bi-gift",
        description: "What came in, and from where.",
        reports: [
          Report.new(label: "Summary", path: reports_donations_summary_path,
            description: "Donations from every source in the date range."),
          Report.new(label: "Itemized", path: reports_itemized_donations_path,
            description: "How much of each item was donated."),
          Report.new(label: "Trends", path: historical_trends_donations_path,
            description: "The last twelve months as a chart. Cached, so up to a day behind."),
          Report.new(label: "From manufacturers", path: reports_manufacturer_donations_summary_path,
            description: "Only donations whose source is a manufacturer, with the top ten by date.")
        ]
      ),
      ReportSection.new(
        label: "Purchases", icon: "bi-cart",
        description: "What you bought, and what it cost.",
        reports: [
          Report.new(label: "Summary", path: reports_purchases_summary_path,
            description: "Totals for the date range, by vendor and by storage location."),
          Report.new(label: "Trends", path: historical_trends_purchases_path,
            description: "The last twelve months as a chart. Cached, so up to a day behind.")
        ]
      ),
      ReportSection.new(
        label: "Product drives", icon: "bi-megaphone",
        description: "Whether a collection event was worth running.",
        reports: [
          Report.new(label: "Summary", path: reports_product_drives_summary_path,
            description: "Donations recorded against drives in the date range.")
        ]
      ),
      ReportSection.new(
        label: "Requests", icon: "bi-clipboard-check",
        description: "What partners asked for, which is not always what they got.",
        reports: [
          Report.new(label: "Itemized", path: reports_itemized_requests_path,
            description: "How much of each item was requested across the date range.")
        ]
      ),
      ReportSection.new(
        label: "Everything else", icon: "bi-collection",
        description: "Reports that do not belong to one subject.",
        reports: [
          Report.new(label: "Annual survey", path: reports_annual_reports_path,
            description: "The yearly figures, one page per year. What NDBN member banks file."),
          Report.new(label: "Activity graph", path: reports_activity_graph_path,
            description: "Received against distributed over the date range, as one chart."),
          Report.new(label: "History", path: events_path,
            description: "Every inventory event, filterable. An audit trail rather than a report.")
        ]
      )
    ]
  end

  def reports_catalog_count = reports_catalog.sum { |section| section.reports.size }
end
