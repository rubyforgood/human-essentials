USER GUIDE DRAFT
# Kits

Many banks distribute kits -- the classic example is a package that contains different types of menstrual supplies (e.g. pads, tampons, wipes).

What the kits feature lets you do is to manage your inventory of what goes into the kits versus what is in the kits.

Working with kits has two steps -- creating the kit and allocating kits

## Creating  versus allocating kits

Creating a kit is defining what is in a kit -- so it's saying that, for example, a period kit will contain 8 tampons and 4 pads.

Allocating kits is akin to assembling kits -- when you create the physical kits from the supplies you have,  you then allocate those kits in the system.  

In our example of a kit with 8 tampons and 4 pads,  if you allocate 10 kits,   you are going to be reducing your inventory of pads by 40 and your inventory of tampons by 80,  but increasing your inventory of period kits by 10.

Then you distribute those period kits.

## Creating a kit

***NB:  You can't edit a kit -- once you've defined it, it's set in stone.  So do be careful! ***

To create a kit,  click on "Inventory", then "Kits" in your left hand menu.  This brings up a page that shows all your current kits.  
Then click the "+New Kit" button on the right hand side of the page.

[TODO:  Screenshot]

This brings up the "New Kit" form, which has the following info:
[TODO:  Screenshot]
- Name:  This is the item name for the kit -- what it will appear as in the drop-down lists and in any reports
- Item is Visible to Partners?  Check this if you allow partners to order the kit.  
Note:  If you need to control which partners can request a kit,  you'll need to put it in a category, through the Item page, after creation, and use partner groups to control which partners can request the item.
[TODO:  link to the Edit Item section] 
- Value for kit:  This is the Fair Market Value for the kit.  We don't sum up the items within the kits for FMV calculations.
- Items in this kit:
  You can enter multiple items,  adding each item with the following
    - Barcode Entry -- if you have already entered [Barcode Items](inventory_barcodes.md), you can just "boop" the item into the kit.
  OR
    - Choose an item from the list of all [Items](inventory_items.md) you have, and add the quantity of the item that will be in the kit.


To add the rest of your items,  click "+Add Another Item."  If you need to remove an item, click "Remove" under it.

Once you are satisfied with the definition of your kit,  click "Save".  This will return you to the kits screen, where you'll see your new kit.

## Allocating kits

Once you have created your kit,  you can allocate it.   This represents assembling kits from their components, and will reduce the inventory of those items appropriately.

From the Kits page (Inventory | Kits),  click "Modify Allocation" on your kit
[TODO: Screenshot]
This takes you to the Kit Allocation page
This lists your current on-hand quantity for each storage location you have kits in, and lets you change the allocation.

Pick the storage location (A) and the amount you want to increase the kits by (B).  When you put a number in the "Change kit quantity ",  you'll see what effect the allocation will have on your inventory.

[TODO: Screenshot]


Note:  you can also 'deallocate' kits if need be, by putting a negative number in the "Change kit quantity by" field.   When you deallocation kits, the contents will be returned to the appropriate items' inventory.

Then click "Save".   The system will check if there are enough of each component item in the storage location.  If there isn't, it will give you an error.  If there is,  it will adjust the inventory appropriately, and return to this screen, which will reflect the new on-hand quantity.

[TODO: Screenshot]

## Deactivating a kit

If you are no longer using a kit,  you can deactivate it - which will remove it from the dropdowns, and from the Kits page (you can always see it by clicking the "show inactive" in the filter, then clicking "Filter")

You can only deactivate a kit if it has no allocations.  To deactivate a kit, click the "Deactivate" button beside it in the Kits page, and then click "OK" to confirm.

## Reactivating a kit

To reactivate a kit, go to the Kits page (Inventory | Kits).
Then click "Show Inactive" and "Filter".   This will show the Inactive kits.
Then click "Reactivate" beside the kit you wish to reactivate and click "OK" to confirm.  

[Prior: Audits](inventory_audits.md)
[Next: Barcodes](inventory_barcodes.md)




















