# 2. Items are tracked using associative models as they move through the system

Date: 2016

## Status

Accepted

## Context

We need a way to have a paper trail of items as they move throughout the system.
The goal is to be able to look at the system at any point in time and, in
theory, re-create all events that have happened so far. An individual item (ie.
a single diaper) should probably not be represented as a discrete record in the
database. This is because both diaperbanks move a lot of volume (hundreds of
thousands of units per year) and also because each individual item of inventory
is unimportant; only the quantities in aggregate are.

## Decision

We will use an associative model ("LineItem") to represent the contents of an
individual transaction within an organization. All transactions involve Items
and Quantities. A separate model ("InventoryItem") will be used to track item
totals within StorageLocations, since their purpose there is slightly different.

## Consequences

Each Transactional model ("Donation", "Distribution", etc) will need to
associate with "LineItem" on a Has-Many-Through basis.
