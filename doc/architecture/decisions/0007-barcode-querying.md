# 7. Barcode Querying

Date: 2018

## Status

Accepted

## Context

We've been using Barcode values that have been recorded as either private (associated only with an organization) or global (available to all organizations). The idea was that Essentials Banks could decide to "Share" a barcode with everyone by making it global, and that this barcode could then be used by others. The implementation, as well as the actual use-cases by Essentials Banks in beta testing, has contraindicated this utility. Additionally, it's unclear how Barcode lookup happens with regard to Base Items.

## Decision

"Global" barcodes are associated with Base Items. Doing a Barcode lookup now does a cascade retrieval. 
 
 1. First, it checks if the organization has defined a barcode with that value. 
 2. If that exists, then it uses that record. 
 3. If it doesn't exist, then it checks to see if that barcode value exists as a global barcode. 
 4. If it exists there, it gets the base item associated with that, and then looks at the organizations items and finds the oldest item with that base item type, and applies it to that. 
 5. If it can't find one for that, then it prompts the user to create a new barcode record.

When we get EAN13 numbers for major products, we can enter those as global barcodes, associated with the generic base items; eg. 48x Pampers 3T and 48x Huggies 3T will both map to the 48x 3T record. 

## Consequences

The primary benefit is that the barcodes will just magically work for most major products (when we get EAN13s entered), while still allowing the organizations to customize to their liking. It's possible since the inference is just assuming the oldest item of that base item type, that it will point to the "wrong" record, but we've yet to encounter that bug report.