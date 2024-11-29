# 3. Multitenancy instead of Multiple Instances

Date: 2016

## Status

Accepted

## Context

Discussion about whether to make this application a multi-tenant (single instance with many Essentials Banks) or single-tenant (each Essentials Bank gets their own instance).

## Decision

We've decided to go with a multi-tenancy. Rails has good support for this, with some initial configuration. This will help keep costs down and allow us to provide it as a cheap/free service. This will require ongoing support by us, to maintain the production instance, but since this is intended to be an ongoing project that was implied anyways. This will also ensure that all Essentials Banks have access to the same version of the software, universally.

## Consequences

We (Ruby for Good) will collectively be on the hook for maintaining a production instance of this, indefinitely. We will also be on the hook for all technical support and bugfixes / patches. On the plus side, support requests will be slightly easier because we will know exactly what they are working with, and we can more quickly respond to feedback.
