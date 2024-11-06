
DRAFT USER GUIDE
# Distributions
Distributions are where you record what you allocate to your partner agencies.

Some things to know:
* Once you save a distribution,  those items are allocated to the partner, and are no longer part of your inventory in the system.
* If you are accepting requests from partners,  you initiate the distribution by "fulfilling" the partner request. (see [Requests](essentials_requests.md))

## Seeing a list of your distributions
To view a list of your distributions,  click on 'Distributions' in the left hand menu.  This brings up a list of all your distributions for the current year.   You can change what distributions are displayed using the distribution filters at the top of the list.


### Filtering the distribution list

[TODO: Insert mini screenshot of just the filtration section here]

When you have been using human essentials for a few months, your distribution list may grow to the point that you really need to be able to narrow things down to find a particular distribution.

To help with that, you can filter the distribution list by several aspects: item, item category, partner, source inventory (i.e. storage location) and distribution status, and date range.
If you pick several things,  you will get only the distributions that match all of them.


Except for date range,  all the filters are specified by picking from a drop-down list as follows
Item: all active items (TODO:  Confirm -- is it just active or are the inactives there too?).  This will filter to only the distributions that contained that item.
Item category:  Item categories (as specified in [Items & Inventory | Item Categories](inventory_items.md)) [TODO:  point right to categories section].  This will filter the list to the distributions that contain items that are in the chosen item category.
Partner:  This will filter the lists to just the distributions to the chosen partner.
Source Inventory:  This will limit the list to the distributions from the chosen storage location.
Status:  Distributions can be Scheduled or Complete. This will limit the list to those with the given status.
Date range:  This is based on the "Distribution date and time" field, ignoring the time.  Date range is selected using a little calendar gizmo with several presets, or by typing the date range into the field.    We highly recommend using the calendar gizmo instead of typing in the field, as the text field is very particular as to the format - we have a few people experiencing mismatches there every month.

When you have have selected your filters,  press "Filter" to do the filtering.  If you still have too many distributions showing, you can add another filter to narrow it down further.

Clicking "Clear filters" will blank out the filters that are drop-down selection, and revert the date range to the current year.

## New Distribution
To enter a new distribution,  click on "New Distribution" in the Distributions list.

Here, you will enter some information about the whole distribution,  then add the all the items that make it up.
The fields include:
- Partner (mandatory)
- Distribution date and time -- this is defaulted to midnight of the current day.  If you want to change it (if, for example, you have a specific time you are scheduling the pickup for), we recommend you use the little calendar gizmo at the right of the field.
  [question:  does send email reminder the day before appear based on an organization flag?]
- Send email reminder the day before  --> causes an email to be sent the day before
  [question:  what happens if we check this and it's today?]
- Agency representative - for information only  [TODO:  is this defaulted from the chosen partner?  It could be.. but do we?]
- Delivery method -- we default this to pickup because it's the most common across banks.
- From storage location:  The storage location the distribution is coming from.  Obviously mandatory.
- Comment
- All the items:
- For each item:
    - If you have set up barcodes for items, you can just boop the item in.  Otherwise,  select the item from the list, and enter the quantity
    - [TODO:  Totally rewrite this bit for packs]
## Exporting Distributions
To export your distributions, click "Export Distributions" on the distributions view.  This will include all the top-level information, and a column [or more, if you use custom units] for each item in the distribution,  in alphabetic order.   It will include all the distributions within the filter you have already applied.
[TODO:  add navigational screenshot and sample csv]
## Viewing a Distribution
To view a distribution,  click "view" beside it in the distributions view.   
This includes the following fields:
- distribution id (for our reference for support) ,
- Source location  (the storage location the inventory came from),
- Agency representative ,
- Delivery method (pickup delivery or shipped),
- Shipping cost (if shipped),
- Comments, and
- the current status.
  [TODO: add screenhot of view]
  [TODO:  check -- do we use "state" throughout -- I feel like we probably use "status"]
## Editing a Distribution
To edit a distribution,  click on "Edit" beside the distribution in the list,  or on "Make a Correction" in the view.

If the distribution is in the past,  you will see a warning to that effect -- because we assumed that you wouldn't normally need to change the distribution once it had gone out the door!
We will give you a stern warning if there has been an audit since the distribution was entered, and you may be prevented from changing some distribution information (such as the storage location), because we just don't know how to handle some of those cases.
[TODO:  More writing about the PACKS version]
[TODO:  screenshot]
## Printing a Distribution
Printing a distribution produces an invoice-like page that can be used as a packing slip.

It is somewhat configurable -- there are options on your [Organization](getting_started_customization.md) page to allow you to: a) add a place for a signature, or b) hide certain columns in the printout.
[TODO:  point that at the exact location in the document]

Please note that your logo (also configurable on the organization, above) is included on this printout -- we strongly advice keeping it fairly small, as a large logo will just be resized anyway, and will potentially break this function.

## Reclaiming a Distribution
What do you do if, for some reason, the distribution that was entered was not picked up?   You can reclaim it,  adding the items back into your inventory.
To do this,  click "Reclaim" beside the distribution in question.
NOTE:  You can not reverse a reclaim.  If you do it by accident, you will have to re-enter the distribution.
[Prior: Requests](essentials_requests.md)[Next: Pick Ups and Deliveries](essentials_pick_ups.md)