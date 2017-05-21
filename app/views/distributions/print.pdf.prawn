prawn_document do |pdf|
  pdf.bounding_box [pdf.bounds.right - 200, pdf.bounds.top - 20], width: 200 do
    pdf.text current_organization.name, align: :right
    pdf.text current_organization.address, align: :right
    pdf.text current_organization.email, align: :right
  end

  data = [["Items Received", "Quantity"]]
  data += @distribution.sorted_line_items.map do |c|
    [c.item.name, c.quantity]
  end
  data += [["", ""], ["Total Items Received", @distribution.total_quantity]]

  pdf.move_down 55

  pdf.font "Helvetica"
  pdf.text "Issued to:", style: :bold
  pdf.text @distribution.partner.name
  pdf.move_down 10

  pdf.text "Issued on:", style: :bold
  pdf.text @distribution.created_at.strftime("%m/%d/%Y")
  pdf.move_down 10

  pdf.text "Comments:", style: :bold
  pdf.text @distribution.comment



  pdf.move_down 20

  # Line item table
  pdf.table(data) do
    self.header = true
    self.cell_style = {
      padding: [5, 20, 5, 20]
    }
    self.row_colors = ["dddddd", "ffffff"]

    cells.borders = []

    # Header row
    row(0).borders = [:bottom]
    row(0).border_width = 2
    row(0).font_style = :bold
    row(0).column(-1).borders = [:bottom, :left]

    # Total Items footer row
    row(-1).borders = [:top]
    row(-1).font_style = :bold
    row(-1).column(-1).borders = [:top, :left]

    # Footer spacing row
    row(-2).borders = [:top]
    row(-2).padding = [2, 0, 2, 0]

    column(0).width = 400

    # Quantity column
    column(1).row(1..-3).borders = [:left]
    column(1).row(1..-3).border_left_color = "aaaaaa"
    column(1).style align: :right
  end

  pdf.move_down 50

  summary = [["Distribution Breakdown", "Quantity"]]
  summary += @distribution.quantities_by_category.to_a

  pdf.table(summary) do
    self.header = true
    self.cell_style = {
      padding: [5, 20, 5, 20]
    }
    self.row_colors = ["dddddd", "ffffff"]

    cells.borders = []

    # Header row
    row(0).borders = [:bottom]
    row(0).border_width = 2
    row(0).font_style = :bold
    row(0).column(-1).borders = [:bottom, :left]

    column(0).width = 400

    # Quantity column
    column(1).row(1..-1).borders = [:left]
    column(1).row(1..-1).border_left_color = "aaaaaa"
    column(1).style align: :right
  end

  pdf.number_pages "Page <page> of <total>", {
    start_count_at: 1,
    at: [pdf.bounds.right - 130, 37],
    align: :right
  }

  pdf.repeat :all do
    # Page footer
    pdf.bounding_box [pdf.bounds.left, pdf.bounds.bottom + 50], width: pdf.bounds.width do
      pdf.font "Helvetica"
      pdf.stroke_horizontal_rule
      pdf.move_down(5)
      pdf.table([[current_organization.name, current_organization.address_inline, ""]]) do
        self.width = pdf.bounds.width
        cells.borders = []
        column(0).width = 125
        column(2).width = 125
        column(1).style align: :center
        column(2).style align: :right
      end
    end
  end
end

