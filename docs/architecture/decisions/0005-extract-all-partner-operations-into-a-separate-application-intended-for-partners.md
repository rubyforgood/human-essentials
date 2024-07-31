# 5. Extract all Partner operations into a separate application intended for Partners

Date: 2018

## Status

Accepted

## Context

Partner organizations work directly with the families in need. Sometimes they will need to collect PII such as address, names and ages of family members, and other contact information. This data is not necessary for Diaperbase to operate, and there are security concerns about that PII being disclosed should there be a breach. There is also a separation of concerns between the two applications; Diaperbase is inventory management and Partnerbase is effectively a CRM. At this time, we belive that they are different enough in their purposes that they should be separate.

## Decision

A new application, Partnerbase, will be created to handle the CRM aspects. It will communicate over a private API with Diaperbase to handle request fulfillment.

## Consequences

Depending on the future features required, this may or may not be the right decision. We now have 2 applications to maintain and there will be duplicated efforts when we have to do updates, as well as a division of labor and domain knowledge. Essentials Banks will not be able to see Partner data, which is both a feature and a liability (since they need some of that for reporting).