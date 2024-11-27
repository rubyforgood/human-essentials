# 4. Instantiating Items from Base Items

Date: 2018

## Status

Accepted

## Context

We encountered a bug where one Essentials Bank edited / deleted Items from the Item list (they weren't using specific Item types). Because Item types were shared globally, this deleted those types for everyone. That needs to not be the case.

## Decision

We've decided to have all items be sandboxed on a per-organization basis. There is a list of templated starting items ("Base Items") that will be created for every new organization when they are first added. Each of those starting items (and all other items) will all be connected back to a Base Item (a generic type). This will allow the Essentials Banks to rename and customize the items to their heart's content without (a) affecting other Essentials Banks and (b) while keeping it possible for Partner Base to request items without needing to know specifically what kinds of items they have on-hand. An "Other" base item will accommodate any items we've not factored in already.

## Consequences

There's some obvious data duplication. If we want to add additional Base Items in the future, we will need to propagate that change out to everyone.