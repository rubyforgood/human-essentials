DRAFT USER GUIDE
#Requests
Requests are how you get the information on what items the partners need.  (You may think of them as orders.)

The unfulfilled ones appear in your dashboard, but you can also manage them in the Requests area.

For a more fulsome description of how the whole shebang works,  see [Partner Management -- Request Distribution Cycle](pm_request_distribution_cycle.md).

## Seeing your unfulfilled requests
We show the unfulfilled requests in two places -- on the [dashboard](essentials_dashboard.md),  and as part of the requests list, which you access by clicking "Requests" in the left hand menu.
[TODO:  insert navigational/request list screenshot]

On the request list,  the requests are in order by the status (with pending first, then started, then fulfilled), then reverse chronological by date
You can view or cancel any request by usin gthe buttons under "Actions"
To see a list of requests, click on "Requests" in the left hand menu

This list is defaulted to a date range of the current year, all items, all partners, and all statuses, ordered by
status, then reverse date (i.e. newest first).

The list contains:
- Date -- the date the request was entered by the partner
- Request was sent by -- the name of the partner that sent the request
- Request sender -- the user that sent the request [TODO:  Double check that we aren't just using the partner email here]
- #of items (request limit)  -- the number of items in the request, and, if you have entered it, the quota for the partner (see [Partners](getting_started_partners.md)[TODO:  Point right to the quota section]
[TODO:  What is the impact of packs on this?]  
- Comments -- the comments the partner entered on the request
- Status 
  - pending -- haven't started fulfilling it yet
  - started -- have started fulfilling, but haven't saved the resulting distribution
  - fulfilled -- have created the distribution for this request
  - discarded -- have cancelled the request
- and the actions you can take on that request
[TODO:  Is it also sorted further by partner name?  or something else?]
[TODO:  Update when we get the default date change in.]

### Filtering your requests
You can filter the request list by:
- Item
- Partner
- Status
- Date range

Fill in the fields with the values you want to filter by, then click "filter"
To reset to the defaults,  click "Clear Filters"

## Product totals
You can find out how much of each product you'll need to fulfill the current filtered open (pending and started) requests by clicking "Calculate Product Totals".
This takes into account the current filters.
[TODO: Navigational screenshot]
[TODO: Screenshot of result]

# Viewing a request
To view a given request, click "View" beside it in the request list.
[TODO:  Navigational screenshot]
[TODO: result screenshot]
This brings up details of the request including:
- partner
- date the request was sent
- who sent the request
- request status
- comments
- and, for each item in the request:
  - Item
  - Quantity
    - If you are using custom units, those custom units will appear here.
  - Total Inventory (across all storage locations)
At the bottom of the screen are buttons letting you start to fulfill the request, or to cancel it.

# Fulfilling a request
To fulfill a request, bring up the request list by clicking on "Requests" in the left-hand menu,  then click on "view" beside the request,  then scroll to the bottom of that screen and click "Fulfill request".
That will bring you into a screen that allows you to specify the details for the distribution based on that request -- you'll see a notice "request started".
Fill in the remaining needed information.  The fields include:
- Partner (It would be rare indeed to change this)
- [TODO:  should it be unchangeable?]
- Distribution date and time (the scheduled pickup delivery or shipment date)
- Send email reminder the day before?
- Agency representative (defaulted to the user who sent the request)
- Delivery method
  - Pick up,
  - Delivery, or 
  - Shipped
- Shipping cost (if the delivery method is shipped)
- From storage location (if you have chosen a default location for the partner, or for your organization,  this will be filled in)
- Comment
- For each item in the request
  - The item
    - When you have chosen the storage location,  the quantity of this item that is available at that storage location will appear here in parentheses.
  - A field for the quantity to be distributed
  - the requested amount.   
    - For any item that has custom units (See custom units in [Getting Started -- Customization](getting_started_customization.md) [TODO:  Point right at the custom units section]
    - If you are using custom units,  the units the partner chose will appear here as well.
You can remove any item by clicking the associated "remove" button, and you can add more items, by clicking the "Add Another Item" button.
  
When you have finished filling in the information, save the distribution by clicking the "save" button
The partner will be sent an email letting them know that their request has been fulfilled.
[TODO:  include sample email]
# Cancelling a request

To cancel a request from the requests list,  click the "cancel" button beside it.   You can also cancel a request from the single request view by clicking the "cancel" button at the bottom of that page.
[TODO: NAvigational screenshots]
In either case,  
You will be prompted to provide a reason for the cancellation, which will be sent in an email to the partner.
[TODO: Screenshot]
[TODO:  Is it just sent to the user who sent the request, or to the partner email and the user who sent the request?]

[TODO: Sample email]
# Exporting requests
To export the requests from the request list,  click "Export requests"
[TODO: Navigational email]
This will create a .csv file with the following information for each filtered request:
- Date
- Requestor (partner)
- Status
- For each of the bank's items.
  - the quantity requested
 Note:  If you use custom units,  there will be a column for each item/unit that is available to be requested. 



[Prior: Purchases](essentials_purchases.md)  [Next: Distributions](essentials_distributions.md)

