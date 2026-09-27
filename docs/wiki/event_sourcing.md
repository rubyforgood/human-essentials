Human Essentials makes use of an [event sourcing](https://microservices.io/patterns/data/event-sourcing.html) pattern to calculate inventory levels. This creates Events in the database, which are then processed to arrive at a final set of values.

## Before Event World

Our previous implementation used the `InventoryItem` class to track inventory. This means that any time something like a donation was changed, we had to look at the current inventory and do things like remove the inventory that was added during the donation, then add it back after the changes were made. This caused particular issues around audits, which allow users to force inventory values to a particular number. Making changes **now** to a donation that happened *before* the audit caused all sorts of weirdness. It also made kit allocation / deallocation extra complex.

Events allow us to focus only on "what happened", and update our business logic as needed to get the correct values out of them.

## Database Tables

The only table used in the inventory side of things is uninspiringly called `Event`. This has the following fields:

* `organization_id` - the organization relevant to the event.
* `event_time` - the time when the event is deemed to have taken place. At the time of this writing, all `event_times` are set to the same time as the event's `created_at` time. (This is because we assume that editing a distribution/donation/etc. does **not** represent a correction of the past, but indicates a change in the *present* - e.g. when the donation was reported on Monday it said there would be 5 diaper packs, but in fact when we got the donation on Wednesday, we only got 4.) However, event sourcing does allow us to set this time to the past, allowing us to correct previous events.
* `type` - the Rails Single Table Inheritance (STI) type of event. This determines the subclass the event should use.
* `eventable_type` and `eventable_id` - combined, this allows us to reference the original "thing" that triggered the event. This could be a Donation, a Distribution, an Audit, etc.
* `group_id` - An ID that we can use to indicate that all events sharing the ID represent the same "thing" happening. This would allow us to (say) group the original creation of a Donation along with all edits to that Donation, and allow us to only process the most recent event for it. Again, practically speaking, all events in the system right now have unique group_ids, and so this feature is not being used.
* `user_id` - the ID of the user that caused the change. This piggybacks on [paper_trail](https://github.com/paper-trail-gem/paper_trail)'s auditing capabilities.
* `data` - the information of what happened in this event. This will be a type inside the `app/events/event_types` folder, such as `InventoryPayload`.

## Types of Events

As of this writing, there are really only three types of events:
* A "normal" inventory event, where inventory is added or removed from a storage location. This includes all event types besides the two special ones below.
* AuditEvent. This is special because it forces inventory values in a storage location to a particular value, rather than adding or removing it.
* SnapshotEvent. This is used either as the starting point for event sourcing (being calculated from existing InventoryItems) or as an optimization so we don't have to load *all events from all history* when calculating current inventory. We currently don't have a process to automatically create these optimizing snapshots, but will add it as necessary. One important difference is that SnapshotEvents work across *all* storage locations, while all other events only apply to a single location.

## Event Data

Event data is strongly typed using the [dry-types](https://dry-rb.org/gems/dry-types/) gem and serialized via Ruby hash (a StructCoder class handles the serialization). A common pattern is to use a hash of (say) storage location ID -> a type representing the storage location, or item ID -> a type representing the item.

## Aggregates

The `InventoryAggregate` class is the one that does the work of reading past events and processing them one at a time to build up the current inventory. The main method is the `inventory_for` method. It can do this with validation turned on or off. If validation is turned on, any time it tries reducing the quantity of an item below zero, it will raise an error. If validation is off, it will not do this behavior.

## View class

There is a special `View::Inventory` class which provides powerful querying and display capability over the inventory aggregate. It can do things like:
* Load items or storage locations from the database to display or query information like name and `active` status.
* Check the quantity of an item across storage locations, or total inventory of a storage location across all items.

In general, when working with inventory in controllers or model classes, `View::Inventory` is probably the class to use.

# Migration Plan

As of this writing, events are being *written* for all organizations, but not being *used* (e.g. on view pages or for validation). There is a flag called `events_read` which powers this behavior. It can be turned on per organization. We also run all our CI tests with the flag both on and off (flag off = "rspec", flag on = "rspec-events"). You can test with the flag on by setting the `EVENTS_READ` environment variable to `true`.

Once all bugs have been squashed, we will remove the flag and clean up / delete all references to `InventoryItem` in the codebase and database.