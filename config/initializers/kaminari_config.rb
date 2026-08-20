# frozen_string_literal: true

Kaminari.configure do |config|
  # One default for every environment. This used to be 5 in development and staging and 50
  # elsewhere, which meant a page under review never looked like the page in production: a
  # reviewer saw a pager on a five-row table and never saw the table that was actually long.
  #
  # Per-table sizes are set explicitly from Pagination's bands; this is the fallback for tables
  # that do not choose one, and is Pagination::MEDIUM written out -- an initializer runs before
  # autoloading, so the constant itself cannot be referenced here.
  config.default_per_page = 25
end
