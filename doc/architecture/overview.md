# Overview

<details>
```plantuml:physical-flow
digraph g {
  rankdir=LR
  node [
    shape=rectangle
    style="rounded"
  ]

  donor -> donation_site -> bank -> storage_location -> partner -> recipient
  donor -> donation_drive -> bank
  purchase -> bank
}
```
</details

![](./physical-flow.svg)

