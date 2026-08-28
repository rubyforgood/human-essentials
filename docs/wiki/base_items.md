*"Organization" and "diaperbank" are used interchangeably in this document*

# Overview
Base Items were added as a significant refactor in Issue #314. There is a model, `BaseItem`, that all `Item`s derive from (though it is not a subclass). There are two endpoints: a read-only global public one, and a read/write endpoint in the Admin namespace. 

When an organization is created, all the existing `BaseItem` records are replicated as `Item` instances for that organization. Organizations have read/write access to their own `Item`s. Practically speaking, this allows each Diaperbank's inventory offerings to be siloed while still allowing a common "language" that we can use to communicate with the Partner Application. 

Each `BaseItem` has a "Partner Key" (a short string `/[a-z0-9_]{4,}/`) that is used as a contextual lookup index (effectively equivalent to an `:id` field, but one that can be used meaningfully from the Partner App, so that a request that fails is human-decodeable about its intent).

## Purpose
The Base Item subsystem is so that organizations have the ability to customize the kind of inventory offered by their Diaperbank: not all organizations may carry the same kinds of products. Feedback from some Diaperbanks indicated that they would like to name or classify their inventory slightly differently, or to omit some items entirely if they aren't ever carried. Not all Diaperbanks run exactly the same, and it would be far more bloating to make the system satisfy all of them *and* it would create a potential hardship (particularly for smaller diaperbanks or those with narrower need) to force all diaperbanks to adhere to certain inventory sets in order to use our software.

## Problems Addressed
The following issues were related to the original problem:
 * [#314 - Item Refactor](https://github.com/rubyforgood/diaper/issues/314)
 * [#250 - Identify models that have side effects problems when their records are deleted](https://github.com/rubyforgood/diaper/issues/250)
 * [#239 - Add ability to "hide" item rows with zero-quantities](https://github.com/rubyforgood/diaper/issues/239)
 * [#229 - Deleting Inventory Items](https://github.com/rubyforgood/diaper/issues/229)
 * [#345 - Add Category Drop-down Menu for creating New Inventory items](https://github.com/rubyforgood/diaper/issues/345) {sorta}

Diaperbanks were editing / deleting Item types because it was different than their offerings. The scale page was breaking because there was mismatch between the Items available and the ones it was expecting (types were hardcoded into the scale page). As we developed plans for externalizing the Partner app, it became clear that there needed to be a "common language" that was shared across all diaperbanks, so that communication with the Partner app would be consistent.

# Architecture
A `BaseItem` instance serves two primary purposes, architecturally:

 1. It serves as a template for the `Item`s that an organization begins with when it is created
 1. It serves as a "parent" to new `Item`s created by an organization

## As a Template
*cf. [/db/base_items.json](https://github.com/rubyforgood/diaper/blob/main/db/base_items.json)*

When an organization is created, a method runs that iterates over all `BaseItem`s and replicates them into `Item` records, using the same name. This allows a generic basis for a new organization to begin using the application, similar to "seeding" data. An organization can then edit, delete, or just use those records as it sees fit, without any worry that it will be disrupting other organizations.

## As a Parent
Every `BaseItem` `has_many :items`, and every `Item` `belongs_to :base_item`. This allows for queries like:
```
> all_3t_diapers = BaseItem.find_by(name: "3T Diapers").items
> all_3t_diapers.pluck(:name).uniq
["3T Diapers", "3T Diapers (boys)", "Huggies 3T", "Luvs 3T", "3T Blue Diapers", "Toddler-size (3) Diapers" ...]
> all_3t_diapers.pluck(:organization_id).uniq
[23, 24, 25, 27, 30]
```

When an organization wishes to add a new `Item` type to their inventory, they are required to pick an existing `BaseItem` as a super-type. This super-type is often listed alongside the `Item.name` in result sets. 

Organizations are never *required* to rename their `Item` records, nor even create alternate subtypes, but the possibility is there, at least, and the `BaseItem` basis ensures that the data does not degenerate too dramatically.

# Integration with the Partner Application
The `BaseItem` "partner key" is the basis through which diapers can be requested. Specifics about how this is exactly implemented are TBD, but in the current MVP implementation, we make the naive assumption that the diaperbanks have a 1:1 mapping between `BaseItem` and `Item`, and are not sub-typing additional `Item`s. This will need to be addressed later, but should not materially affect the implementation (though it may affect the workflow).

# Current List
Per PDX Diaperbank, this is the current list of base item types {{Needs Discussion}}

**Diapers, Baby Disposable**
 * Preemie
 * Newborn
 * 1
 * 2
 * 3
 * 4
 * 5
 * 6
 * 7
 * Swimmers

**Diapers, Pull-ups**
 * 2T/3T Girl
 * 2T/3T Boy
 * 3T/4T Girl
 * 3T/4T Boy
 * 4T/5T Girl
 * 4T/5T Boy
 * S/M ( approx 38-65 lbs)
 * L/XL (approx 60-125 lbs)

*N.B. Girl/Boy subtypes should be done at the `Item` level, not at the `BaseItem` level, unless they truly cannot be used interchangeably (I think this differs from Men's/Women's briefs in that the sizing / form-factor is different for adults?). Should S/M & L/X be split into S, M, L, and XL?*

**Diapers, Cloth**
 * AIO/Pocket
 * Covers
 * Prefolds/Fitted
 * Training Pants/Underwear
 * Swimmers

**Child Diapering Supplies, Other**
 * Wipes
 * Diaper Rash Cream
 * Powder
 * Latex Gloves
 * Bed Pad (cloth)
 * Bed Pad (disposable)
 * Wet Bag

**Adult Incontinence Supplies, Disposable**
 * Liners
 * Pads
 * Men's Shields
 * Men's Guards
 * Men's Fitted Briefs
 * Women's Fitted Briefs

**Adult Incontinence Supplies, Cloth**
 * S/M
 * L/XL/XXL

**Adult Incontinence Supplies, Other**
 * Disposable Underpads (Chux)
 * Cloth Underpads (Chux)
 * Wipes
 * Skin Cream

**Period Supplies**
 * Pads
 * Liners
 * Tampons
 * Menstrual Cups
 * Cloth/Reusable Pads

**Children's Clothing (3 drop downs: item, gender, size)**
 * Item ex: Shirts, Onesies, Shoes, Pants
 * Gender: Girl, Boy, Unknown/Other
 * Size: 0-3m, 2T, 14

*N.B. This needs to be reconfigured and base combinations established. As written, these cannot be directly codified into partner keys*

**Children's Toys and Equipment**
 * Car Seats
 * Pack ‘n’ Play
 * Crib
 * Changing Table
 * Stroller
 * Diaper Bag