# Daily Notebook Refactor — Task Plan

## Goal
Replace the old flat inventory worksheet with one notebook per day containing
three accordion sections: purchasing, dispatch, and damage.

This is a clean break from `inventory_items` and its `good_stock`,
`recoverable`, and `final_waste` model. No compatibility path or alternative
schema is part of this release.

## Confirmed Rules
- A day has one notebook and may have multiple purchasing batches.
- Each purchasing batch owns its `Om`/`Quicklo` source, transport charge,
  other charge, and purchasing lines.
- All quantities and weights are kilograms only.
- Purchasing labour is a total amount per line, not a per-kg rate.
- Damage attribution is selected on every damage row.
- Recovered damage is informational and creates no stock movement.
- Dispatch weight is the row's total weight; amount is `weight × rate`.
- Dispatch uses a free-text destination applied to products selected together
  and does not use clients.
- The notebook does not enforce stock availability.
- Empty and partial drafts can be saved.
- Finalization requires at least one row in any section.
- A finalized notebook is locked until explicitly unfinalized.
- CRUD, dashboard, reports, PDF, and CSV are delivered in the same release.

## Data Shape
`inventory_records` remains the daily notebook header. New section tables are:

```text
inventory_records
├── purchase_batches
│   └── purchasing_items (batch_id)
├── dispatch_items
└── damage_items
```

`purchase_batches` stores source and batch-level charges. `purchasing_items`
references `purchase_batches.id`; it does not store `record_id` directly.

## Section Calculations

### Purchasing
- Line amount = `weight_kg × rate_per_kg`
- Batch total = line amounts + line labour totals + transport + other charges
- Notebook purchasing total = sum of batch totals

### Dispatch
- Line amount = `weight_kg × rate_per_kg`
- Notebook dispatch total = sum of dispatch line amounts

### Damage
- Waste = `damage_kg - recovered_kg`
- Recovered quantity is reporting-only.

## Delivery Scope
1. Database migration and transactional CRUD/finalize APIs.
2. Flutter models, repository, state, and accordion create/edit/detail UI.
3. Dashboard and reports using the new tables.
4. PDF and CSV exports using the same calculations and labels.
5. Tests for validation, totals, lock/unlock behavior, and exports.

## Finalization Validation
The server, not only the UI, must verify:
- the notebook is a draft;
- at least one purchasing, dispatch, or damage row exists;
- every existing row and batch is valid.

Editing and deleting child rows of a finalized notebook are rejected. The
notebook must first be unfinalized.
