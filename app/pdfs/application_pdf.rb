# The base for every printed document: picklists, distribution and donation receipts, purchase
# records.
#
# A document is an ERB template in app/views/pdfs, laid out in app/views/layouts/pdf.html.erb and
# styled by app/assets/pdf/pdf.css, then turned into a PDF by sghtmltopdf -- an HTML-to-PDF
# engine that runs in-process with no browser behind it. See ADR 0013 for why it replaced Prawn.
#
# Subclasses keep the interface the Prawn classes had, `new(organization, record)` and
# `#compute_and_render`, so the controllers and DistributionMailer did not change.
class ApplicationPdf
  include ItemsHelper

  # A column of the line item table, and how its cells print.
  #
  #   :text      left-aligned, as written
  #   :numeric   right-aligned
  #   :quantity  right-aligned and emphasised -- the figure the reader is counting
  #   :check     an empty box to tick
  #   :write_in  left blank and wide, for handwriting
  Column = Data.define(:label, :kind) do
    def css_class
      case kind
      when :numeric, :quantity then "numeric"
      when :check then "check-column"
      when :write_in then "write-in"
      end
    end
  end

  # The line item table: columns, body rows, and an optional totals row.
  Table = Data.define(:columns, :rows, :totals)

  attr_reader :organization

  def initialize(organization)
    @organization = organization
  end

  # The PDF, as a binary String.
  def compute_and_render
    Sghtmltopdf.render(to_html)
  end

  # The HTML the PDF is made from. Useful on its own: open it in a browser to inspect the layout.
  def to_html
    ApplicationController.render(template: template, layout: "pdf", assigns: {pdf: self})
  end

  # The view under app/views that lays the document out, written out in full in each subclass so a
  # search for the path -- and bin/design/dead-code.rb -- finds what renders it.
  def template
    raise NotImplementedError
  end

  # The text above the title, and the PDF's <title>.
  def document_name
    raise NotImplementedError
  end

  # The bank's logo, or Human Essentials' when it has not uploaded one, as a `data:` URI.
  #
  # Embedded rather than referenced because an uploaded logo lives in Active Storage -- S3 in
  # production -- and the engine does not fetch remote resources. Embedding the default too keeps
  # one code path, and means a document renders the same under the engine's server mode, which
  # shares no filesystem with the app.
  def logo_data_uri
    if organization.logo.attached?
      data_uri(organization.logo.download, organization.logo.content_type)
    else
      data_uri(File.binread(Organization::DIAPER_APP_LOGO), "image/png")
    end
  end

  private

  # A Table from the rows-of-cells shape the receipts build: a header row of labels, the body, and
  # a totals row last. The first column is the item name and is text; the others are figures,
  # and the ones named in `quantities` are the counts.
  def table_from(data, quantities:)
    headers, *rows, totals = data
    columns = headers.each_with_index.map do |label, index|
      kind = if index.zero? then :text
      elsif quantities.include?(label) then :quantity
      else :numeric
      end
      Column.new(label, kind)
    end
    Table.new(columns, rows, totals)
  end

  def data_uri(bytes, content_type)
    "data:#{content_type};base64,#{Base64.strict_encode64(bytes)}"
  end
end
