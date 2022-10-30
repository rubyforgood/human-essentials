# Overview

![Physical flow](./physical-flow.svg)
<details>
<summary>(Diagram Code)</summary>

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
</details>


![Partner Request](./partner-request.svg)
<details>
<summary>(Diagram Code)</summary>

```plantuml:partner-request
participant Partner as partner
participant Bank as bank

partner -> bank: Submit request
bank -> bank: Build distribution
bank -> partner: Fulfill distribution
```
</details>
