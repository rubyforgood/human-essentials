# Page sizes for index tables.
#
# One number does not fit every table here, because the rows are not the same height. A row on
# /users is 45px; a row on /purchases is 205px, because it carries a wrapped list of line items.
# That is a 4.5x spread. At a single size of 50, /purchases is 10,250px of table -- about eleven
# screens -- while /users is two and a half. At a single size of 15, /users needs five clicks to
# show what fits on one screen.
#
# So the size is banded by how tall the table's rows are. Every band lands the full page between
# roughly two and three and a half screens, which is the range where scrolling still feels like
# reading one page rather than paging by hand.
module Pagination
  # Rows that wrap: line items, addresses, multi-line summaries. ~120-205px each.
  TALL = 15

  # The ordinary case: a row of short cells that may wrap to two lines. ~60-90px each.
  MEDIUM = 25

  # Dense rows: a few short cells, no wrapping. ~45-60px each.
  COMPACT = 50
end
