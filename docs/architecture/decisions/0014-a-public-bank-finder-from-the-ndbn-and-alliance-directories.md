# 14. A public bank finder, from the NDBN and Alliance directories

Date: 2026-10-19

## Status

Accepted

## Context

`/account_requests/new` asked whether the visitor was an essentials bank or a partner agency. A
lot of organizations that *want* diapers answered "bank", because the partner answer gave them
nothing but two directory links and a "contact your bank". Each of those requests costs a super
admin a rejection.

The two directories that would answer them are the National Diaper Bank Network's member
directory and the Alliance for Period Supplies' allied programs. Both pages are Google My Maps
embeds. Measured on 2026-10-19: 244 and 194 records, 347 once merged by name, 72 offering both.
Each record has a name, a headquarters city and state, and a website. **None has an address**, and
only 26 of the 438 points carry coordinates.

## Decision

**A public page, `/find-a-bank?near=…`, lists the banks nearest a city, state or ZIP.** The account
request page's question became *What are you looking for?*, and its first answer, *Diapers or period
supplies*, reveals a search box that submits to it.

- **The listings are imported from each map's KML export**, not scraped from the page:
  `https://www.google.com/maps/d/kml?mid=<id>&forcekml=1`. `BankListingImportService` reads both,
  merges a bank that is in both by its normalized name, and replaces `bank_listings` wholesale.
- **Weekly, from `clock.rb`**, by `BankListingImportJob`. The import refuses to replace the list
  if either export fails, or comes back empty or with less than half last week's count. When it
  refuses, it emails super admins and the old list stays, because a moved or emptied map would
  otherwise empty the finder without anyone knowing.
- **Locations come from the Census Bureau's Gazetteer files, not a geocoding service.** Places,
  county subdivisions and ZIP Code Tabulation Areas, 93,094 rows, are committed as
  `lib/assets/census_locations.csv.gz` (1.5MB). The migration that creates `census_locations`
  loads them, and so do the seeds. A bank is placed at its headquarters city, and a search at the
  city or ZIP typed.
- **Distance is great-circle miles between those points**, computed in Ruby over the few hundred
  listings. The page says *about* N miles, and says so when nothing is within 50.

### Alternatives rejected

- **Geocoding each search with the app's existing `geocoder` gem (Nominatim).** It would accept a
  street address. It would also send every visitor's typed location to OpenStreetMap, and its
  usage policy caps it at one request a second and needs attribution. Street-level precision is
  wasted when the banks are only known to the city.
- **Scraping the directory pages.** Both render their lists inside the map iframe, so there is
  no list on the page to scrape. The KML export is the data the map itself is drawn from.
- **Asking NDBN and the Alliance for an API or a CSV.** Still worth doing, and nothing here
  prevents switching sources. Waiting for it would leave the account request problem unsolved.
- **Results inline on the account page (preview option B), or a button to a separate finder
  (option C).** Previewed side by side in `docs/mockups/bank-finder-designs.html`. B crowds the
  question and gives the results no URL. C puts a step in front of the people the change is for.

## Consequences

**Two tables that are not scoped to an organization.** `bank_listings` and `census_locations` are
reference data shared by every tenant, like `base_items`. Neither is a Human Essentials customer
record.

**The sources can move.** If NDBN or the Alliance replaces its map, the My Maps ID in
`BankListingImportService::SOURCES` changes. The import refuses the empty export, and the email
says which directory and where to update it.

**Cities the Census does not name are aliased by hand.** Measured on 2026-10-19, 13 of 347
listings named a neighborhood, village or county (the Bronx, Hyannis, Kamuela), and 5 were
misspelled ("Worchester"). `CITY_ALIASES` and `CITY_CORRECTIONS` cover them, and every import
logs any new city it cannot place, so the list can be extended.

**The Census files change once a year.** `bin/rails "census_locations:build[dir]"` rebuilds the
committed file from a new year's downloads. A city incorporated since 2024 is unknown until then.

**Republishing the directories is a relationship, not only a technical choice.** Both maps are
public, and the finder links each source on every page. NDBN should still be told before this
ships.
