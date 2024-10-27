DRAFT USER GUIDE
# Items
## Introduction
Your bank is initialized with  a basic set of Items that contains many common product types that essentials banks distribute.   These items represent the stock you have for distribution.  Here is the current default list:  

- Adult Briefs (Large/X-Large),
- Adult Briefs (Medium/Large),
- Adult Briefs (Small/Medium),
- Adult Briefs (XS/Small),
- Adult Briefs (XXL),
- Adult Briefs (XXS),
- Adult Briefs (XXXL),
- Adult Cloth Diapers (Large/XL/XXL),
- Adult Cloth Diapers (Small/Medium),
- Adult Incontinence Pads,
- Bed Pads (Cloth),
- Bed Pads (Disposable),
- Bibs (Adult & Child),
- Cloth Diapers (AIO's/Pocket),
- Cloth Diapers (Covers),
- Cloth Diapers (Plastic Cover Pants),
- Cloth Diapers (Prefolds & Fitted),
- Cloth Inserts (For Cloth Diapers),
- Cloth Potty Training Pants/Underwear,
- Cloth Swimmers (Kids),
- Diaper Rash Cream/Powder,
- Disposable Inserts,
- Kids (Newborn),
- Kids (Preemie),
- Kids (Size 1),
- Kids (Size 2),
- Kids (Size 3),
- Kids (Size 4),
- Kids (Size 5),
- Kids (Size 6),
- Kids (Size 7),
- Kids L/XL (60-125 lbs),
- Kids Pull-Ups (2T-3T),
- Kids Pull-Ups (3T-4T),
- Kids Pull-Ups (4T-5T),
- Kids Pull-Ups (5T-6T),
- Kids S/M (38-65 lbs),
- Liners (Incontinence),
- Liners (Menstrual),
- Other,
- Pads,
- Swimmers,
- Tampons,
- Underpads (Pack),
- Wipes (Adult), and
- Wipes (Baby)




[TODO: "Kit" is a base item, and it is in the "new" bank on staging.    Is it one of the items that is initialized?  Shouldn't be, IMO] 


"Under the hood" each of these basic items belongs to a particular reporting category used for the annual survey, such as disposable diapers, cloth diapers, kits (which are made up of other items), cloth diapers, and other.

You can add more items, basing them off our base item list, and customize them.   The things you can do include:
 - hiding them from your partners (useful if, say, you only distribute kits, but get donations of materials that go into the kits)
 - grouping them into categories (you can limit which categories groups of partners can access) 
 - adding minimum and recommended bank-wide inventory levels (which enable warnings, and drive the low inventory list in your dashboard)
 - creating [kits](inventory_kits.md) that will contain items (the inventory levels will show the items that are yet not in the kits)
 - remove the items from your lists on a go-forward basis.
 - 
[TODO:  links pointing to each of these things]

## The Items & Inventory Views

This is a multi-tabbed view - you have several angles to look at your items and bank-wide inventory (if you want to see everything that's in a particular storage location, that's under [Storage Locations](inventory_storage_locations.md))
### Item List
This shows all of your items, and allows you access to view/edit/and delete them.
[ToDo: screenshot]
#### Viewing an item
Clicking "View" will bring up details on the item, including all the things you can change, and a breakdown of the inventory at each location you currently have stock at.
[ToDo: screenshot]
The fields are:
- Base item -- this is the "base item" for this item -- which determines what section it is in for the Annual Survey.  You can also search by base item (at this time)
- Category -- this is a category you define (see Item Categories, below 
- 
- [TODO:  put the link in])
- 
- Value per Item -- this is currently shown in cents (there is a request to change it to dollars in our list).  This is used for any "Fair Market Value" values -- including on donation and distribution printouts.  
Note: We only have one 'value per item' per item -- so it's always the current fair market value not the historical.  If provided, this is used for the value column on the distribution and donation printouts (unless you hide those columns when [customizing your bank](getting_started_customization.md))
- Quantity per individual -- This is used for two things:  1/  If you have enabled "request by individual" for your partners (and they use it), this is the number of items that will be in their request per individual they request for.  (so, if it's 25, and they indicate 3 individuals,  you will receive a request for 75 of that item).  It is also used in the annual survey for the estimated people served -- we take the total of the item that was distributed, and divide it by this number to get the number of people helped.  **NOTE** We use 50 for this if you don't give a value.
- On hand minimum quantity -- This is a bank-wide on-hand minimum quantity of the item -- being below this triggers the item appearing in your low inventory report in red.
- On hand recommended quantity -- This is the amount you want to have on hand -- if you don't have this, it will appear in the low inventory list on your dashboard, just not in red.
- Package size -- If you use this, the calculated number of packages for the item will appear on the distribution printout, unless you hide it when [customizing your bank](getting_started_customization.md).
- Item visible to partners -- This is useful if you have items that you do not want the partners directly requesting.   Uses include: items you don't get very often,  of items you only have because they are going into kits you haven't assembled yet. You can uncheck this to hide those items from all your partners.
#### Editing an item
Clicking "Edit" beside an item on the item list lets you edit the item definition, with the fields as described above. **NOTE*:  Value per item is in dollars on this screen. 
#### Deleting vs Deactivating an item
The button "delete" will only appear beside an item if there hasn't been any activity on it at all.  

The button "deactivate" will appear if there has been activity.  But it will be greyed out unless your bank-wide level of inventory on that item is 0.
Deactivating an item removes it whenever you are entering a new distribution/donation/purchase/transfer/audit, and removes it from the partner's new requests.

### Item Categories 

Item categories are largely used for limiting the items specific [Partner Groups](pm_partner_groups.md) can see, though you can also filter distributions by them.  This tab shows all the item categories you have, allowing you to view and edit each one, as well as enter new ones.

**Note:  Each item can only belong to one category **

[TODO:  Question - why do we not filter Donations, Requests, or Purchases by them? ]  

[TODO:  Screenshot]
#### Adding a new item category
To add a new item category,  Click on Inventory, then Items & Inventory, then the Item Categories tab, then the "Add Item Category" button.  

Enter a unique Category Name, and a suitable description, then click Save.

#### Viewing an item category
All the information about an item category is in the list of all of them,  but you can also manage the items in the category through the view.  To view an item category,  you click on Inventory, then Items & Inventory, then the Item Categories tab, then the "View" button.  
[TODO: Screenshot]

You can also remove items from the category by clicking "Remove from category" beside the item.   This will hide them from any partner groups that have this category.  

#### Editing an item category
[TODO:  "Update Record on this isn't our usual terminology  -- should be Edit Item Category -- add that to the inbox]

To edit the name and description of an item category,   To view an item category,  you click on Inventory, then Items & Inventory, then the Item Categories tab, then the "Edit" button beside the category you wish to edit.  
[TODO: Screenshot]

Update the category name (still needs to be unique) and category description, and click save.  This will take you to the item category view [Add pointer to above], which lets you change the items in the category.

### Items, Quantity and Location tab

[TODO:  We should highlight the bank-wide ones that are below the minimum.  Add that to the inbox ]

This tab shows all the item inventory across all the storage locations, along with each item's minimum quantity, recommended quantity, and bank-wide quantity.  

[TODO: Screenshot]

### Item Inventory tab

This tab shows the bank-wide inventory for each item.   Clicking the + beside the item name will show the breakdown of that inventory by storage area.

[TODO:  Raise the question of whether we really need both the Items, Quantity and Location tab at a Stakeholder's circle.]

### Kits tab
This shows the same information as the main [Kits](inventory_kits.md) view. 

[TODO:  Note the filter does not work on this view.  Add to inbox.]


[Prior: Partner Announcements](pm_announcements.md)[Next: Storage Locations](inventory_storage_locations.md)












