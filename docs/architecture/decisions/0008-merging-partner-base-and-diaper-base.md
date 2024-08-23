# 8. Merging Diaperbase & Partnerbase into singular application

Date: 2021 (added late in Oct 2022)

## Status

Accepted

## Context

The application was originally two applications; Diaperbase and Partnerbase whom both lived on different repos. The original decision to have a separate application was based on the security perks of isolating data so that sensitive data would not leak from one application to the other. We noticed that 
the costs of maintaining two applications outweighed the benefits of having two applications. Therefore, in 2021 we decided to merge the two applications.

## Decision

Merge the two applications into a unified application named Human Essentials (changed due to being more inclusive, as we serve period banks now). 
Change came into effective after https://github.com/rubyforgood/human-essentials/pull/2084 was merged in 2021.

## Consequences

Merging the two applications has the benefit of reducing complexity for ease of maintaince. However, a great deal of refactor work is
needed to remove old concepts that were based on two applications (aka redundant models). In the interim, the data modeling is confusing
until we refactor.
