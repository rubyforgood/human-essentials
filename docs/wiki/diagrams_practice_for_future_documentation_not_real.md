This is a practice page for diagrams. **These are not accurate!** This is using the built-in [Mermaid Declarative Diagrams](https://mermaid-js.github.io/mermaid/) syntax.

## Core relationships
```mermaid
erDiagram
  user }|--|{ organization : "Belongs to"
  partner ||--|{ request : "Requests a distribution"
  request }|--|| organization : "From a bank"
```

## Partner Request Workflow
```mermaid
sequenceDiagram
  Partner ->> Bank: Request a distribution
  Bank ->> Partner: Fill
```

```mermaid
sequenceDiagram
  Rando person ->> Bank: Drop off a donation
  Bank ->> Bank: Catalog and create inventory
```