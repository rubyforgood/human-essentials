This document is intended for general reference, but primarily for facilitating on-boarding of developers that are new to Diaperbase. Please feel free to contribute to this document, but bear in mind:

 - The purpose of this document is to provide a preliminary understanding of how this app functions
 - The audience is "Rails developers", so it's ok to use Rails jargon, but concepts related to diaperbanking may need to be explained
 - Aim for a level of specificity that is functional: it should explain how data flows through the app, but avoid being overly technical about implementation, unless it's particularly noteworthy or a potential danger area

# Background
Diaperbanks are similar to Foodbanks, if you've heard of those before. They are small repositories of sanitary materials primarily used by infants and children, and the typical recipients are underprivileged or lower-income families. According to the National Diaperbank Network (NBDN), there are ~120 registered diaperbanks, and likely many others that are not registered with the NBDN. Diaperbanks also occasionally provide other sanitary materials such as menstrual supplies, car seats, and other items that can be dispensed to defray the costs of child-rearing.

One of the biggest problems consistently faced by Diaperbanks is the means to track their inventory, which sometimes sprawls across multiple storage locations. Most of them typically come up with some spreadsheet-based solution (Excel, Google Sheets, etc.), though some have used free or low-cost inventory software applications. Both solutions present challenges, either lack of data integrity and high labor cost in maintenance (the former) or lack of extensibility for adapting to new features (the latter).

# Purpose
This application is a solution that is custom-tailored around the specific needs of Diaperbanks. We initially worked directly with several diaperbanks to ascertain exactly how we could best meet their needs with software, and we offer it to them for free, since many diaperbanks are volunteer-driven and/or grant-funded, and any money they would spend on an application is money diverted from swaddling children.

The scope of this application (Diaperbase) is:

 - tracking incoming, outgoing, and retained inventory in a robust manner
 - providing reports and status of the inventory to the diaperbanks
 - facilitating their reporting needs (to both the NBDN as well as any Grantors and community partners)
 - providing fulfillment for incoming requests from community partners (via PartnerBase, see Appendix)

Things that are out of scope include:
 - Directly tracking data of families, children, and recipients of sanitary supplies
 - Directly working with community partners (see Appendix)
 - Any eCommerce functions (including the purchasing or vending of inventory)
 - Performing Human Resource functions

# Introduction
Before we delve into the inner-workings of how this application functions, we'll begin with a 10,000 foot view of how inventory moves through the application. This will include some key terms in **bold**, those terms will be further defined in the Appendix.

## The Flow of Data
![diaperbase-diagram](https://user-images.githubusercontent.com/502363/51081485-5eb49100-16be-11e9-9d10-c8bfa6572968.jpg)

### Intake
A Diaperbank will acquire inventory primarily through one of two methods: a **Donation** or a **Purchase**. Purchases are straightforward; the Diaperbank spends its own money to purchase inventory. Donations can be received through a few different means.

**Diaperdrives** are like food drives -- a campaign, typically with advertisement to the community, for the general public to provide needed items to the diaperbank. Sometimes people will also donate inventory at a local **Donation Site**, outside of a Diaperdrive. Other than those two primary methods, there is a miscellaneous classification for diapers that are received (but not purchased) through other means.

Donations can also dropped off at **Donation Sites**. These are locations that have been designated as places where people can drop off donations.

Donations that don't fit into either of those types are classified as "Miscellaneous Donations."

Both Donation Sites and Diaper Drives have to be created in the application beforehand, but can be used repeatedly after that.

### Retention
All inventory is physically stored at **Storage Locations**. This is one area where the application is particularly useful, as some storage locations accrue large quantities of inventory over time. Each storage location can contain any number of **Items** or types of items, and if a diaper bank has multiple storage locations, it is possible for the same item type to exist at multiple locations. 

Sometimes, the diaper banks will need to make a correction, though this application calls them **Adjustment**s.

When a diaper bank wants to move inventory from one storage location to another, they do so with a **Transfer**.

### Output
When inventory leaves a diaper bank, it does so via a **Distribution**. These are either created implicitly from inbound Partner Base **Requests**, or created explicitly via the menu interface. When they are created explicitly, they pull from a single designated Storage Location, and are built in a similar fashion to Donations, Adjustments, Transfers, etc -- items are added and quantities are specified.

Distributions can be exported as PDFs, which diaper banks can use as printable manifests for the packages sent to the community partner.

Community Partners then dispense the items they receive to the clients / families.

# Application Architecture
This section is a more detailed, and more technical, explanation of how the application works, internally.

## Multi-Tenancy
This application is multi-tenant -- that is, each Diaper Bank (used interchangeably with **Organization**) has its own templated "section" of the application, and may act in that section without concern that its changes will affect other organizations (and vice versa).

When a user is signed-in, they are automatically "isolated" to their organizational space, as indicated by the URL (which features a short-code of their organization in it).

### Users
Every organization has a user who is the "organization admin", typically the first user to sign up for that organization. This user can perform administrative privileges on the organization, such as changing the descriptive details, inviting other users, etc. Additional users are able to use most of the functions of their organizational space.

## Items
These are an important, but perhaps not immediately intuitive, aspect of the application. Items are, for example, "3T Diapers", or "Baby Wipes", or "Boys Batman 4T Diapers" -- they can be as generic or as specific as necessary, and organizations have full control over what items they use in their instance of DiaperBase.

Every Item is also connected with a "Base Item". The Base Items are all very generic and refer to a functional commonality -- "3T Diapers", "Huggies 3T Diapers", "Boys Batman 3T Diapers" would all have "3T Diapers" as their Base Item base. 

For a much more detailed and technical description of how these work, see the Wiki article on [Base Items](/rubyforgood/diaper/wiki/Base-Items).

Base Items are only really noticeable in two places: When creating a new item, and when communicating between PartnerBase and DiaperBase. Aside from those, they're more of a concern of the `SiteAdmin` role. For the remainder of this document, when it refers to "Item", it is referring to `Item`, unless otherwise specified.

### Item "Boxes" (LineItems & InventoryItems)
Because Items are only defining *types* of physical inventory, we need a vehicle to track *quantities*. This application does this by piggybacking on the association. We currently use two different kinds of associations: **Line Items** and **Inventory Items**. The main practical difference between the two is that the quantities of "Line Items" are non-zero integers and the quantities of "Inventory Items" are natural numbers.

#### Line Items
These are the most common, and are used polymorphically for numerous models. The name "line item" was chosen because a "line item" is a single line on a list of items, perhaps found on a manifest or roster. In this application, line items are like a plain box, labeled with an item type, that some number of items are put into. That labeled box can only hold that kind of item, it can also hold negative quantities of that item.

Line Items are used in Donations, Distributions, Adjustments, Transfers, Purchases, and generally any place where inventory is being moved somehow.

The behaviors of Line Items are consistent enough that the logic has been captured largely in the [Itemizable](/rubyforgood/diaper/blob/master/app/models/concerns/itemizable.rb) model concern.

#### Inventory Items
Inventory Items are similar to Line Items in their function, except it might be better to abstractly think of them as "Shelves" -- they are only found in Storage Locations, and are the resting place for inventory while it's retained by the Organization. Like Line Items, each Inventory Item can only track a single item type, but instead of associating with a polymorphic type, they only associate with Storage Locations (which hold physical inventory). They also differ in that they cannot be negative (you can't have -5 Baby Wipes, right?)

## Barcoding
One of the reasons that DiaperBase was built was specifically to offer the ability to expedite inventory tracking with Barcodes. If you aren't familiar with the physical concept of how Barcodes function, read up on [Code 39](https://en.wikipedia.org/wiki/Code_39) specifically - this allows us to encode letters and/or numbers into machine readable barcodes.

The TL;DR is that the barcode stripes correspond with actual letters and numbers, and when the barcode reader reads it, it just converts it into the alphanumeric version, and appends a carriage return.

Our Barcode UI controls specifically look for "an alphanumeric string followed by a carriage return (CHR 13)", and will use that to issue a lookup via Ajax.

### Organization Barcodes
Organizations are encouraged to create their own Barcodes. So long as the barcode value has not already been used by that organization, they are free to use whatever Code39 barcode value they like.

Suggested uses include:

 * Using the actual UPC on the packaging
 * Creating barcodes that meaningfully track the item name and quantity in the value (ie. 100X3TDIAPERS)
 * Creating barcodes that track custom bundles the diaper bank frequently dispenses

Organization barcodes always take precedence when they do a lookup.

### Global Barcodes
These are barcodes that act as "fall-throughs" and will generally be used to track product UPCs and map them to the appropriate Base Item type. (For example: pointing the UPC for 40 Huggies 3T, 48 Pampers 3T, and 24 Luvs 3T diaper packs all to the "3T Diapers" Base Item type). These are only entered by Site Administrators, and must always point to a Base Item type.

### Barcode Retrieval
Barcode records are either connected to an organization and an `Item`, or they are labeled "global" and connected to a `BaseItem`. When a lookup is requested, it will look up the barcode (by its value) with this order of priority (this was established in [#593](/rubyforgood/diaper/issues/593)):

 1. Does the organization have its own barcode defined with this value? (yields an `Item`)
 2. Is there a global barcode defined for this value? (yields a `BaseItem`)
 3. Prompt the user to create a new barcode record using this value

For the second item, after the `BaseItem` is retrieved, it consults back to the Organization and finds the oldest `Item` (for that organization) that uses the retrieved `BaseItem`.

# Appendix

## Definitions & Terms

(Note - in the following sections, the term "diaper bank" and "organization" are used interchangably.

**Adjustment** - When a diaper bank has to make a change to its on-hand inventory totals, it creates an adjustment. A single adjustment can record the change of quantities for multiple different kinds of items. These adjustments create a record internally for transaction and are the only interface for an organization to make direct changes to their inventories. They are internally modeled as `Adjustment`.

**Base Item** - This is the abstract base type for an Item object, and is used as the source of replication when a new organization is created. Every Item must inherit from a Base Item. 

**Diaper Drive** - This is similar to a fund-raiser or food-drive. It is an often advertised campaign to the community with a declared intention to encourage donations from community members. Sometimes the Diaperdrive is held by individuals or organizations that are not the Diaperbank themselves. Diaperbanks like to track data on how successful their diaperdrives are, so we provide a means to track it. Internally, this is represented by the `DiaperDriveParticipant` model.

**Distribution** - These are how diaper banks issue inventory to community partners. A distribution can sometimes be connected with a request from Partner Base, but this isn't strictly required. The distribution builds a manifest of items & quantities and ultimately handles the removal of inventory in a transaction. It's the primary interface for reducing inventory.

**Donation** - This is one of the two ways that inventory is added to a Diaperbank. Donations are inventory that is provided at no cost to the Diaperbank. Internally, they are represented by the `Donation` model. These are the primary interface for adding inventory to a diaper bank. When a donation completes, it creates a transaction to add the inventory.

**Donation Site** - These are physical locations where the general public can bring needed inventory to be donated to the Diaperbank. They have a geographical address and are generally named. Internally, they are represented by the `DonationSite` model.

**Inventory Item** - These are an abstract "box" that records an item type with a quantity, and is generally held by a Storage Location. It is internally represented by the `InventoryItem` model. (See also: Line Item)

**Items** - These are the data abstractions of real-world product *types*. They are internally represented with the `Item` model. An instance of `Item` is owned by an Organization. Items do not have quantities themselves, the quantities are tracked in the associative records (such as `LineItem` or `InventoryItem`). Items are created from `BaseItems` when new Organizations are created.

**Kit** - A kit can be considered a package of products that can be tracked together. Each kit has a single associated `Item` which can be used as a `LineItem` or `InventoryItem`. Kits can be assigned to storage locations; when this is done, the products within the kit are removed from that storage location and the kit itself is added.

**Line Item** - These are an abstract "box" that records an item type with a quantity, and is generally held by a model that is transporting inventory through the flow of the system (i.e. it is usually used when transferring inventory from one place to another, such as via donations). It is internally represented with the `LineItem` model. (See also: Inventory Item)

**Organization** - The software abstraction of a Diaper Bank, itself, and used interchangeably as a term. Internally represented with the `Organization` model.

**Partner** - This refers to a "Community Partner", an individual or organization in the surrounding community that works directly with the families, tracks their data, and schedules distributions of diapers and sanitary supplies. Sometimes this will be referred to as a "Partner Organization" or "Community Partner". Partners request disbursements of inventory from a Diaperbank, the Diaperbank fulfills those requests, and then the Partner provides them to the families.

**Purchase** - This is inventory that was purchased for cash by the diaperbank, directly. We track these so that the diaperbanks can report how much money they spent directly on inventory. Internally, these are represented by the `Purchase` model.

**Request** - Requests are initially created by the Partner Base application and are sent via an API. When they are received by Diaper Base, they are tracked internally and are transformed into Distributions. These are represented internally by the `Request` model.

**Storage Location** - These are warehouses of physical inventory, though they can be as small as someone's closet or storage room in their apartment, or as big as an actual building. Internally, they are represented by the `StorageLocation` model. Storage Locations are unique to each organization and are not shared across organizations.

**Transfer** - These are transactional objects created to track the movement of inventory from one Storage Location to another, and to leave a paper trail behind. They are internally represented by the model `Transfer`.

## Partnerbase
[Partnerbase](/rubyforgood/partner) is a companion application built in-tandem with this application. It interfaces directly with the Community Partners that work with the recipients of the sanitary supplies. Both applications are dependent on one another, but each address separate needs and so are maintained separately. They connect via an API. Please see the Partnerbase repository for more information.