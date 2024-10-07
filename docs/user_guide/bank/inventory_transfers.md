DRAFT USER GUIDE
# Transfers
If you have multiple storage locations, sometimes you have to move inventory between them.  
[TODO:  Throughout - doublecheck what requires org_admin, vs what needs org user]
## Working with Transfers
To start working with transfers, click "Inventory",  then "Transfers" in the left-hand menu.
That will bring up the transfers page, which lists all your past transfers in chronological order.  From here you can make a new transfer, add a transfer, view the details of a past transfer or delete it.
You can filter the transfers based on source (From), destination(to), and date.

[TODO: Screenshot]
## Adding a transfer
To add a transfer, click the "+New Transfer" button on the transfers page.  That will bring up this screen.

[TODO: Screenshot]

Specify where the items being moved are coming from, in "From Storage Location," and where they are going to in "To storage location".

The Comment field is a good place to note the reason for the transfer, but you can leave it blank.

Then select the item and quantity for each item that is being transferred.  If you have [barcodes](inventory_barcodes.md) set up,  you can use your barcode reader to "boop" in the materials being transfered.

When you are done, click "Save".  The system will check that you have enough inventory in "From" to cover the transfer.  If so, the inventory changes will take place immediately.

[TODO:  Make clear on each item where it might be unclear when the inventory changes happen.   Probably should write something in the intro for that too]

## Viewing the details of a transfer
To view the details of a transfer, click the "view" button beside it in the transfers list.

[TODO: Screenshot]  

This lists all the items in the transfer, and how much was transferred, as well as your comment.

## Deleting a transfer

To delete a transfer, click the "delete" button beside the transfer, and press "OK" to confirm.
This check that the inventory levels in the two storage locations will allow the change.  If they will, it will roll back the inventory changes that were made when you entered the transfer.

##### ** N.B. This is not undoable  *** 

----

Note:  If you do delete the wrong transfer, you don't have to panic, but it will be a hassle. You can find a record of any transfer made since September 2024 in the "History" Report to grab the numbers and re-enter it.  The inventory changes in that case will be as of the date you re-enter, though.

----

## Exporting transfers
To export a list of the transfers, click "Export Transfers" on the transfers page
[TODO: Screenshot]
[TODO : screenshot of sample export]

The details in the export are lacking -- it doesn't show each item, but only the total.
[TODO:  Add a better export to the Things to do]

[Prior:  Adjustments](inventory_adjustments.md) [Next: Product Drive Participants](community_product_drive_participants.md)