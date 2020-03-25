# 2. Leave Application Public Without Identities

Date: 2020-03-22

## Status

Accepted

## Context

Mae and Aaron discussed whether or not to require authentication or
authorization in the application. There is concern about whether requiring
sign-up creates an unnecessary barrier to using the application by groups that
are already under a great amount of distress. They are already using Google
Sheets (fully public), so there would be no additional risk of data leaking that they
are not already accepting with current solutions. Scoping each community to ZIP
code would at least provide a modest partition between groups.

We can always add in authentication later once we see how the application is
used in the wild, and get some actual feedback from users.

## Decision

We will not be using Devise or creating any kind of identity to connect
user-submitted content. All CRUD will be fully public and community-marshalled.

We will use robots.txt to instruct search engines not to index content in the
user-submitted areas.

We will instruct users that anything they post will be publicly visible and that
they should take care to remove information after it is resolved.

## Consequences

Users will be able to more use the application and get help / list offers.
Moderation will be impossible. A vulnerable population will have semi-personal
data exposed to the public.
