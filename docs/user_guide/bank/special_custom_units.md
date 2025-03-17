# Custom Units (opt-in feature)(in beta testing)

Custom Units addresses a long-standing problem that diaper banks, in particular, experience:

- On the one hand, when you are tracking raw inventory, writing grant proposals, or working with the NDBN, you need to know how many individual diapers you distribute.
- On the other hand, partners often want to work in terms of "packs" of diapers.

Unfortunately,  there isn't a standard number of diapers in a "pack", even in the same size (sometimes not even with the same brand!), so we can't just convert one to the other.

Custom Units is our solution so that the partners can order in terms of "packs", "boxes", "flats", etc., but you as the Bank still work in terms of individual diapers.

You can specify different units (e.g. packs, boxes, flats) that the partners can use to order items, or the partner can still request them by the number of individual items ("units").

You'll see the number of "packs" that the Partner requested, but when creating the Distribution you'll enter the number of individual Items you actually distribute.

(It's not a perfect solution!)

We call this approach "Custom Unit" Requests.

## Setting up Custom Units

For a Bank to allow **Custom Units** to be used for Partner Requests, they must first configure which units are allowed and which Items use custom units.

### Set up your organization units

First, set up all of the units that you want to use.

- Click `My Organization`
- Click `Edit`
- In the "Custom Units" section, add in all of the Custom Units that you want to use
  - Use lower-case singular names, e.g. "pack", "box", and "flat"
  - You can make up your own unit names
  - Other unit ideas: "large pack", "small box", "1-month box"
- Save changes

![Organization level units setting](images/special_custom_units/Organization_level_units_setting.png)

### Set up units for specific Items

Next, you need to indicate which Items should have Custom Units.

- Go into the Inventory → Items & Inventory page, in the "Item List" section
- Select an Item, such as "Kids Pull-Ups (5T-6T)", click `Edit`

![Item config edit button](images/special_custom_units/Item_config_edit_button.png)

- Indicate what units you would like Partners to be able to use when requesting this Item
  - In the example below, we picked "pack" and "flat"

![Item config request units checkboxes](images/special_custom_units/Item_config_request_units_checkboxes.png)

Allowed units are then shown in the "Custom Request Units" column of the Item list.

![Item config list shows units](images/special_custom_units/Item_config_list_shows_units.png)

## How Partners use Custom Units in Requests

When a Partner places a Request, they fill out a form indicating the Items they are requesting. If the Item is configured to have Custom Units, they must now select the units for that Item.

![New Request units](images/special_custom_units/New_Request_units.png)

The units field is only provided for Items that have Custom Units configured. The Partner must make a selection in this field, but can choose "Units" to indicate that they want that number of individual Items no matter how they're packaged.  

![New Request units only on configured Items](images/special_custom_units/New_Request_units_only_on_configured_items.png)

The confirmation screen shows the requested units.

![Request confirmation popup](images/special_custom_units/Request_confirmation_popup.png)

Once the Partner confirms the Request, Human Essentials will show them a success page that includes the requested units.

<img src="images/special_custom_units/Success_page.png" border=1 />

The email sent to the Partner will also indicate the requested units.

<img src="images/special_custom_units/Email_with_units.png" border=1>

The Request History page shows the units alongside the Item quantities.

![Request history units](images/special_custom_units/Request_history_units.png)

## Processing Requests with Custom Units

The request detail includes any Custom Units chosen for each Item.  

![Open requests with units](images/special_custom_units/Open_requests_with_units.png)

From the Request list, clicking `Print Unfulfilled Picklists` button generates a Picklist. The Request Picklist PDF lists units when they are specified on an requested Item.

![Request pick list pdf with units](images/special_custom_units/Request_pick_list_pdf_with_units.png)

When you create a Distribution from a Request, you must enter the distributed quantity of the requested Items. The quantity will be defaulted to the requested amount only for those Items where either there are no Custom Units available or the Partner chose "Unit", but you will see the requested number and units (if applicable) for each Item as well.  

[!NOTE] The "Quantity - Total Units" is individual units! 

So if the Partner requested "9 boxes" of Pads, and each box has 10 Pads, then you would put "90" in the "Quantity - Total Units" field (assuming you are providing the full 9 boxes).

![Distribution creation from a request](images/special_custom_units/Distribution_creation_from_a_request.png)

Distributions are always created in terms of raw quantity, not requested units.

## Other reporting

From the list of Requests, you can click on `Calculate Product Totals` to get a summary of the request quantities. These are separated out by the different units requested.

![Product totals calculation](images/special_custom_units/Product_totals_calculation.png)

Similarly you can export Requests as a CSV.  This will include a column for each allowed Item/unit combination.

