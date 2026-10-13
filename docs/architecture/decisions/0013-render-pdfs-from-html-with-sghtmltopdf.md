# 13. Render PDFs from HTML with sghtmltopdf

Date: 2026-10-12

## Status

Accepted

Supersedes the use of Prawn, which no ADR recorded. Follows
[11. Adopt the Ruby for Good design system (Tailwind v4)](0011-adopt-the-ruby-for-good-design-system.md).

## Context

The app prints four documents: picklists, distribution receipts, donation receipts and purchase
records. Distribution receipts are also attached to the email `DistributionMailer` sends.

All four were drawn with Prawn. Each one was a Ruby class that placed text by cursor arithmetic:
`move_up 24`, a bounding box 225 points from the right edge, `font_size 12` and then back to 10.
That had three costs.

- **None of the design system reached them.** The screens moved to Figtree, slate neutrals,
  hairline tables and sentence case, and the documents kept Open Sans, grey zebra stripes, a
  2-point black rule under Title Case headings, and `[  ]` typed as a checkbox.
- **Layout was position, not structure.** Two columns were made by printing the left one, moving
  the cursor back up by a guessed height, and printing the right one. A long partner name or a
  missing contact pushed one column into the other.
- **The four were copies.** Each class carried its own letterhead, table and footer code.
  `PurchasePdf` alone duplicated roughly 110 lines of `DonationPdf`, and `docs/design-decisions.md`
  already named extracting a shared base as the follow-up nobody had done.

## Decision

Write each document as an ERB view and convert it with **sghtmltopdf**.

- `app/pdfs/application_pdf.rb` renders `app/views/pdfs/<name>.html.erb` inside
  `layouts/pdf.html.erb` through `ApplicationController.render`, and passes the HTML to
  `Sghtmltopdf.render`.
- The subclasses keep the interface the Prawn classes had: `new(organization, record)` and
  `#compute_and_render`. The controllers and the mailer did not change.
- `app/assets/pdf/pdf.css` styles them. It is plain CSS, not Tailwind, with the design
  system's tokens written out as values. It sits in its own directory, not `app/assets/stylesheets`,
  because `spec/assets/asset_resolution_spec.rb` guards against Bootstrap's return by asserting
  that directory does not exist.

sghtmltopdf is a Rust HTML-to-PDF engine that runs in-process through a native extension. It
ships precompiled for every platform in `Gemfile.lock` that the app deploys to, and needs no
browser, no subprocess and no Node.

### Alternatives rejected

- **Keep Prawn and restyle it.** Restyling would still mean cursor arithmetic. It is the cheapest
  change and leaves every one of the three costs in place.
- **Grover, or Ferrum printing to PDF.** These drive a headless Chrome. The app already has
  Chrome for the system specs, but only in test. Production would need a browser on every web
  host, and a request would wait on a browser process.
- **wicked_pdf.** This wraps wkhtmltopdf, which is no longer maintained and renders with an old
  Qt WebKit. sghtmltopdf describes itself as its successor and keeps wicked_pdf's option names.

## Consequences

**The documents are views.** A change to a document is a change to ERB and CSS, and the
letterhead, title, fact tiles and line item table are partials shared by all four.
`ApplicationPdf#to_html` returns the HTML on its own, so a layout can be inspected in a browser.

> Amended 2026-10-12, the same day: the fact tiles and title figure were replaced by banded
> sections before any of this was pushed. The shared partials are now the letterhead, page
> header, details, line items and signatures. The decision this record makes, rendering with
> sghtmltopdf, is unchanged. See `docs/design-decisions.md`, "The printed documents became the
> app's record page".

**The engine supports a subset of CSS.** It has no `!important`, no gradients, no `font`
shorthand and no percentage `border-radius`. `gap` works on flex containers only, weights of 600
and above all print bold, and fonts must be TrueType. `pdf.css` records each limit where it
applies.

**Figtree ships twice.** `public/vendor/figtree` holds the woff2 files the screens use, and the
engine cannot read woff2. `app/assets/fonts/figtree` holds the static TTFs, under the SIL Open
Font License, copied beside them. Open Sans, which only Prawn used, is deleted.

**Font URLs must be Propshaft logical paths.** The stylesheet says `url("figtree/Figtree-Regular.ttf")`.
Propshaft digests that when precompiling, and `sghtmltopdf_stylesheet_link_tag` maps the digested
URL back onto `public/assets`. A relative `../fonts/...` path worked in development and fell back
to a system font in a precompiled build. That was caught by rendering from a production-mode copy
of the app before commit.

**PDFs are not byte-reproducible.** The engine stamps each file with its creation time and a fresh
document ID, and ignores `SOURCE_DATE_EPOCH`. The golden-file specs compared bytes, so they now
compare the text `PDF::Reader` extracts, saved under `spec/fixtures/files/pdf_text/`. Two of the
old golden PDFs stay in `spec/fixtures/files/`, because the partner document upload specs use them
as ordinary attachments.

**The generic `ruby` platform left `Gemfile.lock`.** sghtmltopdf's source gem cannot build without
the Rust core, so Bundler dropped `ruby` from `PLATFORMS`. Every platform CI and the deploy target
use is still listed, each with a native gem. A contributor on an unlisted platform, such as
Windows, would need the engine's HTTP server mode instead.

**A logo is embedded, not fetched.** An uploaded logo lives in Active Storage, which is S3 in
production, and the engine fetches nothing remote. The logo goes into the HTML as a `data:` URI.
