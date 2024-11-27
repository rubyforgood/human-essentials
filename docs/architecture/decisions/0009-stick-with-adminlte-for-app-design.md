# 9. Sticking with AdminLTE for design needs.

Date: Oct 2022

## Status

Accepted

## Context

The application's design is mainly based on [AdminLTE](https://adminlte.io/) which is a open source design library based off of boostrap. In 2022, TailwindCSS 
was introduced in hopes to make the application easier to maintain. And subsequently, a theme was picked out to replace AdminLTE that is based on TailwindCSS.
However, the team decided in a meeting that the benefits that TailwindCSS could offer does not outweigh the efforts to migrating to a new framework. 

## Decision

1. Remove the use of TailwindCSS and stick with Bootstrap
2. Rally the styling to more fully utilize [AdminLTE](https://adminlte.io/). Refer to AdminLTE's demo for any widgets or UX/UI decisions we may need. Copy & pasting should work!

## Consequences

Any work that used TailwindCSS would need to be updated to use Bootstrap 4 instead. Contributors & maintainers seeking to update the frontend should refer to [AdminLTE](https://adminlte.io/).

