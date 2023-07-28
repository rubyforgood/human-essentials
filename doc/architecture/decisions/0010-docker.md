# 10. Using Docker

Date: July 2023

## Status

In Review

## Context

Many developers like to use Docker for their local environments, particularly contributors who may want a temporary developer environment to use and then discard. Docker can also make initial setup a lot easier when it works. However, Docker moves developer setup complexity from the contributor setting up the environment to the maintainers of the application. In addition, there can be differences based on the OS Docker is running on. Docker changes are challenging for maintainers to test as all testing is manual. This repo has seen a lot of churn around Docker setups in the past. Docker sometimes requires us to make small changes to the application itself that would be otherwise unnecessary.

Wants Docker | Docker is broken
---|---|---
#1893 | #503
#603 | #430 / #438
#1856 | #432
#277 | #369 / #374
- | #327
- | #319

#502 is reported as a docker issue, but was actually a seeds issue.

## Decision

Docker **will not** be officially supported by human-essentials, however a Dockerfile and docker-compose.yml will be provided as a starting point for engineers who want to setup and use Docker independently.

## Consequences

Docker will be added to the app, and documented, but not supported. It will permanently be an experimental setup option.