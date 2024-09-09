DRAFT USER GUIDE
# Purchases
The other major way we add to inventory in human essentials is through purchases.

In Human Essentials you enter in-kind donations by specifying the vendor, where they are being stored, and how many of each item are included. 

## Seeing all your purchases

To view a list of all your purchases, click on 'Purchases', then "All Purchases" in the left-hand menu,

[TODO:  Insert navigational screenshot here.]

This screen includes filters so you can narrow down your search to a particular purchase, and some basic information on each purchase:
- Purchases from - the vendor you purchased the goods from
- Storage location -- where you are stored the goods from this purchase.
- Comments
- Quantity of items -- the total number of items in the purchase
- Variety of items -- the number of different items in the purchase
- Amount spent (in dollars)
- FMV -- this is the Fair Market Value of the purchase using to the current fair market value of the items in it.  Fair Market Value can be entered on the item in [Inventory | Items](inventory_items.md)  [TODO:  Make that point to the appropriate section witin inventory items once we have it written]
- Actions - you can view more details on each purchase from this screen.

### Filters
You can filter your purchases by single storage location , by single vendor, or by purchase date range.  

[TODO: mini screenshot of filter section]
The vendors and storage locations are selected using drop-down lists of all the storage locations / vendors. 
Date range is selected using a little calendar gizmo with several presets.   We highly recommend using the calendar gizmo instead of typing in the field, as the text field is very particular as to the format - we have a few people experiencing mismatches there every month.
Once you have selected your values,  click Filter to make the list conform to your selection.  To reset the selection, just click "Clear Filters".  This will set the list to all the purchases from the current calendar year.


## Entering a new purchase
To enter a new purchase,  you can either click "Purchases | New Purchase" on the left hand menu, or click the +New Purchase button on the Purchases list
[TODO:  Navigational screenhot]
[TODO:  screenshot of new purchase screen]
Enter the following information (starred items are mandatory):
### Vendor *
  Select the vendor from a drop-down list of all your vendors, but if you choose "Not Listed", you can enter a new vendor on the fly.  You have to enter at least one of the business name and contact name, but we recommend both (there is a current issue where only the business name shows up on dropdowns)
[TODO: screenshot of NewVendor form]
### Storage Location *
   Select the storage location from a drop-down list of all your active storage locations.
### Purchase Total *, and broken down purchase totals 
The purchase total has to be greater than 0,  and it should equal the sum of the 4 fields that break down the purchase into categories.   These are used in the Annual Survey report.
### Comment
Self explanatory, we hope?  This shows up on the all purchases list [TODO:  update this if we have included it into the purchase details]
### Purchase date
This should be the date the purchase was made - it is defaulted to today's date.  This is used for filtering,  but also for what year the purchase is included in for the annual survey.
### Items in this purchase
There are a couple of ways to get items into the purchase quickly:  
(1)You can "bloop" a barcode in to get your items into the system -- that requires some initial setup, as detailed in [Inventory | Barcodes] or (2)  You can pick the item from the drop-down of all *active* items in your system, and enter the quantity of that item.  
In either case,  you can click "Add Another Item" (3)  to open up another item for entry, or "Remove" (4) if you've added too many!
The quantity here is meant to be individual items (e.g. diapers), rather than packs.   The reason behind this is that, ultimately, your reporting will be based on the number of individual items,  and package size is inconsistent across manufacturers.

Note:  If you make two entries with the same item, they will be added together when you view them later.

When you are done entering your items,  click "Save".  Barring any errors, this will return you to the "All Purchases" page

## Viewing a purchase
To view a single purchase, click the "View" button beside it on the All Purchases list.
## Editing a purchase
Editing a purchase should be relatively rare, but it happens.  To Edit a purchase,  view it (see above), then click "Make a correction"
## Deleting a purchase
If, somehow, you have entered a purchase in error, you can delete it by viewing it, then clicking Delete, and then "OK".  This is a permanent deletion -- you can't undo it.
## Exporting your purchases
You can export your purchases from the "All Purchases" screen, above.  This creates a .csv file containing all the information for each of the purchases in your filtered list.
