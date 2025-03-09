# Custom Units (opt-in feature)

Partners place requests with Banks, listing out the items and quantities that they are requesting. By default the quantity unit is unspecified. A Bank may treat the quantity as individual units, or a count of manufacturer-provided packs, or a count of re-packaged containers, and so on.

Banks may use the **Custom Units** feature to be specific about which items should be requested with particular packaging and counted as as a whole.

## Why You Might Want Custom Units

Custom Units addresses a long-standing problem that diaper banks, in particular, experience:

- On the one hand, when you are tracking raw inventory, writing grant proposals, or working with the NDBN, you need to know how many individual diapers you distribute.
- On the other hand, partners often want to work in terms of "packs" of diapers.

Unfortunately,  there isn't a standard number of diapers in a "pack", even in the same size (sometimes not even with the same manufacturer!), so we can't just convert one to the other.

Custom Units is our solution so that the partners can order in terms of "packs", "boxes", "flats", etc, but you as the Bank still work in terms of individual diapers.

You can specify different units (e.g. packs, boxes, flats) that the partners can use to order items, or the partner can still request them by the number of individual items ("units").

You'll see the number of "packs" that the partner requested, but when creating the distribution you'll enter the number of individual items you actually distribute.

(It's not a perfect solution!)

We call this approach "Custom Unit" Requests.

## Setting up Custom Units

For a Bank to allow **Custom Units** to be used for Partner Requests, they must first configure which units are allowed and which items use custom units.

### Set up your organization units
![Organization level units setting](images/special_custom_units/Organization_level_units_setting.png)

- Go into the Organization Page
- Edit
- In the "Custom Units" section, add in all of the custom units that you want to use
  - Use lower-case singular names
  - For example "pack", "box", and "flat"
  - You can make up your own unit names
  - Other unit ideas: "large pack", "small box", "1-month box"
- Save changes

### Set up units for specific items

![Item config edit button](images/special_custom_units/Item_config_edit_button.png)
- Go into the Inventory → Items & Inventory page, in the "Item List" section
- Select an item, for example "Kids Pull-Ups (5T-6T)", click `Edit`

![Item config request units checkboxes](images/special_custom_units/Item_config_request_units_checkboxes.png)
- Indicate what units you would like Partners to use for requests of this item
  - For example, you can select "pack" and "flat"

![Item config list shows units](images/special_custom_units/Item_config_list_shows_units.png)

Allowed units are then shown in the "Custom Request Units" column of the Item List.

## How Partners use Custom Units in Requests

![New Request units](images/special_custom_units/New_Request_units.png)
When a Partner places a request, they fill out a form indicating the items they are requesting. If the item is configured to have Custom Units, they must now select what is the units of their request.

![New Request units only on configured items](images/special_custom_units/New_Request_units_only_on_configured_items.png)

Units are only required for items that hae custom units configured. The request can also use "Units" to indicate that they want that number of unique items no matter the packaging.

![Request confirmation popup](images/special_custom_units/Request_confirmation_popup.png)

The confirmation screen shows the requested units.

<img src="images/special_custom_units/Success_page.png" border=1 />

Once the request is confirmed, the Partner will receive a success page with the requested units.

<img src="images/special_custom_units/Email_with_units.png" border=1>

The email sent to the Partner will also contain the requested units.

![Request history units](images/special_custom_units/Request_history_units.png)

The Request History page shows the units alongside the item quantities.

## Processing Requests with Units
![Open requests with units](images/special_custom_units/Open_requests_with_units.png)

The request detail includes the units for each item.

![Request pick list pdf with units](images/special_custom_units/Request_pick_list_pdf_with_units.png)

From the Request list, clicking `Print Unfulfilled Picklists` button generates a picklist. The request picklist PDF lists units when they are specified in the request.


![Distribution creation from a request](images/special_custom_units/Distribution_creation_from_a_request.png)

When you create a distribution from a request with units, you must enter the quantity of the items that are being distributed. **NOTE! The "Quantity - Total Units" is individual units!**. So if the Partner requested "9 boxes" of Pads, and each box has 10 Pads, then you should put "90" in the "Quantity - Total Units" field.

Distributions are always created in terms of raw quantity, not requested units.


## Other reporting

![Product totals calculation](images/special_custom_units/Product_totals_calculation.png)

From the list of requests, you can click on `Calculate Product Totals` to get a summary of the request quantities. These are separated out by the different units requested.

Similarly you can export requests as a CSV and there are separate columns for each allowed item and unit.

