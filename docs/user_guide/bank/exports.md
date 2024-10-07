DRAFT USER GUIDE
# Exports
[TODO:  Screenshots throughout,  if we need them]

There are several exports available to allow you to use the information from the application in other apps.
These all export files in .csv format, which is importable by all common spreadsheet programs.
Many of these can be filtered down to the information you might need for a specific communication need.

The exports available include (in alphabetical order): 
- adjustments
- annual survey
- barcode items
- distributions
- donations
- donation sites
- items
- partners
- product drives
- product drive participants
- purchases
- requests
- storage locations
- transfers
- vendors

## Adjustments 
[TODO:  The adjustments export needs to be better to be actually useful]
### Navigating to export adjustments
Click "Inventory", then "Inventory Adjustments" in the left-hand menu.  Then click "Export Adjustments", 

### Contents of adjustment export
Creation date, Organization, Storage Area, Comment, # of changes.

### Notes:  
We have improving the adjustments export to include the changes made in each adjustment on our todo list. We'll also remove the organization as redundant information.

Please reach out if this is a priority for you.


## Annual Survey 
[TODO:  Raise question -- shouldn't this be an export *across* years?]
### Navigating to export annual survey
Click "Reports", then "Annual Survey" in the left-hand menu.  Then click the year of the report you want to export.  Then click "Export Report."
### Contents of annual report export

For more information on these, please see the [Annual Survey Report](reports_annual_survey.md)

- Disposable diapers distributed,
- Cloth diapers distributed,  
- Average monthly disposable diapers distributed,  
- Total product drives,  
- Disposable diapers collected from drives,  
- Cloth diapers collected from drives,  
- Money raised from product drives,  
- Total product drives (virtual),  
- Money raised from product drives (virtual),  
- Disposable diapers collected from drives (virtual),  
- Cloth diapers collected from drives (virtual), 
- Disposable diapers donated, 
- % disposable diapers donated, 
- % cloth diapers donated, 
- Disposable diapers purchased,  
- % disposable diapers purchased, 
- % cloth diapers purchased, 
- Money spent purchasing diapers, 
- Purchased from, 
- Vendors diapers purchased through, 
- Total storage locations, 
- Total square footage, 
- Largest storage site type, 
- Adult incontinence supplies distributed, 
- Adult incontinence supplies per adult per month, 
- Adult incontinence supplies, 
- % adult incontinence supplies donated, 
- % adult incontinence bought, 
- Money spent purchasing adult incontinence supplies, 
- Period supplies distributed,  
- Period supplies per adult per month,  
- Period supplies, 
- % period supplies donated, 
- % period supplies bought, 
- Money spent purchasing period supplies,  
- Other products distributed, 
- % other products donated, 
- % other products bought, 
- Money spent on other products, 
- List of other products, 
- Number of Partner Agencies, 
- Agency Type 
- Zip Codes Served,  
- Average children served monthly,  
- Total children served,  
- Repackages diapers?,  
- Monthly diaper distributions?,  
- % difference in yearly donations,  
- % difference in total money donated,  
- % difference in disposable diaper donations
## Barcode Items
### Navigating to export barcode items
Click "Inventory" then "Barcode Items" in the left-hand menu.   Then click "Export Barcode Items."
### Contents of barcode items export
For each Barcode Item:
- Item Type,
- Quantity in the Box, 
- Barcode
## Distributions
### Navigating to export distributions
Click "Distributions" in the left hand menu.  Click the "Export Distributions" button.
### Filtering the distributions export
The distributions export shows the same distributions as are in the main distributions page, and the filtering works the same way.
Before clicking the export button, you can filter by any of:
- date range (we recommend you use the calendar-style selection rather than typing it in, as the format is a bit fussy.)
- item
- item category
- partner
- source inventory (i.e. storage location)
- status (i.e. scheduled or complete)

Specify the filtration you want, then click "filter".   

### Contents of distributions export
For each of the distributions in the filtered list:
- Partner,
- Initial Allocation (when the distribution was entered),
- Scheduled for,
- Source Inventory,
- Total Items,
- Total Value,
- Delivery Method,
- Shipping Cost,
- State,
- Agency Representative,
- Comments, 
- and the quantity in the distribution for each of your bank's items.

Note:  This includes inactive items as well as active ones.
[TODO:  confirm that that statement is accurate]

## Donations


### Navigating to export donations
Click "Donations", then "All Donations" in the left hand menu, then click 'Export Donations'.
### Filtering the donations export
The donations export shows the same donations as are in the main donations page, and the filtering works the same way.
You can filter by any of:
- Storage Location
- Source (i.e. Manufacturer, Product Drive, or Misc. Donation)
- Product Drive
- Product Drive Participant
- Manufacturer
- date range (we recommend you use the calendar-style selection rather than typing it in, as the format is a bit fussy.)

When you have selected your filters,  click "Filter", then "Export Donations"

### Contents of the donations export
For each of the donations in the filtered list:
- Source
- Date (this is the date you enter in the donation, rather than the date it was put into the system)
- Details (this is the manufacturer name or the product drive)
- Storage Location,
- Quantity of Items (the total quantity of items)
- Variety of Items (the number of different items)
- In-Kind Value,
- Comments, 
- and the quantity of each of your organization's items in the donations.

## Donation Sites
The donation sites export is not yet implemented.  If this is a priority for you, please reach out.

## Items
### Navigating to export items
Click "Inventory", then "Items & Inventory" in the left hand menu.  Then click "Export Items"
### Filtering the item export
By default, the export will contain all active items.
You can filter it differently by only including the items for a specific base item,
or by also including inactive items.
Select what you wish to filter by,than click "Filter".

### Contents of the item export
For each filtered item, the export includes:
- Name,
- Barcodes (each barcode associated with that item),
- Base Item,
- Quantity (across your entire bank)

## Partners
The partners export contains high level information about the partner.  It does not contain the information in the partner profile.

[TODO:  Do we neeed a partner profile export?]
### Navigating to export partners
Click "Partner Agencies", then "All Partners" in the left-hand menu.  Then click "Export Partner Agencies"
### Filtering the partner export
By default, the partner export shows all the active partners.
You can export different groups of partners by clicking the partner filters which exist for the various statuses:
- Uninvited
- Invited
- Awaiting review
- Approved
- Error 
- - (TODO:  Check if error is a current thing, or perhaps a relic of the two db system?)
- Recertification required
- Decactivated
- Active
[TODO:  add contents]

### Partner Export contents
For each partner in the filtered list:
- Agency Name,
- Agency Email,
- Agency Address,
- Agency City,
- Agency State,
- Agency Zip Code,
- Agency Website,
- Agency Type,
- Contact Name,
- Contact Phone,
- Contact Email,
- Notes

## Product Drives
### Navigating to export product drives
Click 'Community', then 'All Product Drives' in the left hand menu,  then click "Export Product Drives"
### Filtering the product drives
The product drives can be filtered by 
- name, 
- item category, and 
- date range.  

It is defaulted to all drives, this year. [TODO:  This will need updating when we change the default timespan]
To filter the export, make your selections, then click "Filter" before clicking "Export Product Drives".

### Product Drive Export content
For each filtered product drive, the export will contain:
- Product Drive Name,
- Start Date,
- End Date,
- Held Virtually?,
- Quantity of Items,
- Variety of Items,
- In Kind Value, and 
- the quantity donated for each item in alphabetical order.
- 
## Product Drive Participants
### Navigating to export product drive participants
Click 'Community', then 'Product Drive Participants' in the left hand menu,  then click "Export Product Drive Participants"
### Product Drive Participant Export content
- Business Name,
- Contact Name,
- Phone,
- Email,
- Total Diapers
  - The title for this should be Total Items, as that is what is shown.
  - [TODO:  initialize issue for this discrepency]
## Purchases
### Navigating to export purchases
Click 'Purchases', then 'All Purchases' in the left hand menu.  Then click "Export Purchases"
### Filtering exported purchases
You can filter the purchases by:
- Storage location
- Vendor
- Purchase date

The default is all storage locations and vendors, and the current year 
[TODO:  update this when we change to 60 days prior, 30 days forward]

Make your selection and click "Filter"  before clicking "Export Purchases"
### Content of Purchases Export
For each purchase in the filtered list:
- Purchases from (the vendor name) (TODO:  Shouldn't this be Purchased from,  or Vendor?)
- Storage Location,
- Purchased Date,
- Quantity of Items,
- Variety of Items,
- Amount Spent (all currency amounts are in dollars),
- Spent on Diapers,
- Spent on Adult Incontinence,
- Spent on Period Supplies,
- Spent on Other,
- Comment, and
- the quantity of each item included in the purchase.

## Requests
### Navigating to export requests
Click 'Requests' in the left-hand menu, then "Export Requests"
### Filtering exported requests
You can filter the exported requests by the following:
- Item
- Partner
- Status (Pending, Started, Fulfilled, Discarded)
- Date Range
Make your selection, then click 'Filter' before clicking 'Export Requests'

The default is all requests in the current year

(TODO: update the default if we get to that before this is published)

### Contents of requests export
For each filtered request,
- Date,
- Requestor (i.e. partner)
- Status, and
- the quantity of each item requested.  
  - Note: If you have packs enabled (upcoming feature), there will be a column for each unit that you have enabled for each item.  Otherwise, one column per item.

## Storage Locations
### Navigating to export storage locations
Click "Inventory", then "Storage Locations" in the left-hand menu. Then click "Export Storage Locations"
### Filtering exported Storage Locations
You can filter the exported list by Item.  This will give all storage locations that have ever had that item, *not* those with current inventory.
(Note:  including inactive is currently broken)
[TODO: Write up including inactive]
[TODO:  Check that by item filter works for export storage location]
The default is all active storage locations.
[TODO:  IT looks like the export doesn't include the inactive when selected.]
Make your selections, then click "Filter" before clicking "Export Storage Locations"
### Contents of storage location exports
For each storage location in the filtered list:
- Name,
- Address,
- Square Footage,
- Warehouse Type,
- Total Inventory, and 
- Quantity for each of the organization's items.

## Transfers
### Navigating to export transfers
Click "Inventory", then "Transfers" in the left-hand menu. Then click "Export Storage Locations"
### Filtering exported transfers
You can filter the transfers by:
- From location
- To location
- date range.  
  - Note that this is the date the transfer was entered in the system, which may or may not be when it happened.

The default is all the transfers for the current year (Note: we are soon changing this to 60 days prior, 30 days forward from today).

Make you selection and click 'Filter' before clicking "Export Transfers".

### Contents of transfers exports
For each selected transfer:
- From,
- To,
- Comment,
- Total Moved
- (TODO:  Really?  This should have the total moved for each item.   Make an issue to make it so.)

## Vendors
### Navigating to Export Vendors
Click "Community", then "Vendors" in the left-hand menu.  Then click "Export Vendors"
### Contents of vendors export
- Business name
- Contact name
- phone
- email
- address

[Prior: Manufacturers](community_manufacturers.md) [Next: Summary reports](reports_summary_reports.md)

