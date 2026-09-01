# Purchasing Section — Spec

## Behavior
The daily notebook contains zero or more purchasing batches. Each batch has:
- source: `om` or `quicklo`;
- transport and other charges;
- zero or more product lines while the notebook is a draft.

A line contains product, weight in kg, rate per kg, and a total labour charge.
Its amount is `weight_kg × rate_per_kg`. Labour is not multiplied by weight.

Empty or partial batches may be saved in a draft. Finalization validates every
batch and requires at least one row across all notebook sections.

## UI
Purchasing is an accordion section. Inside it:
- add, edit, remove, and reorder batches;
- select source and enter charges on each batch card;
- add or remove product rows;
- show read-only line amounts and live batch/notebook totals.

All monetary inputs must be non-negative. Finalized notebooks render read-only
until unfinalized.

## SQL Shape
```sql
CREATE TABLE purchase_batches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  record_id UUID NOT NULL REFERENCES inventory_records(id) ON DELETE CASCADE,
  source VARCHAR(20) NOT NULL CHECK (source IN ('om', 'quicklo')),
  transport_charge DECIMAL(12,2) NOT NULL DEFAULT 0
    CHECK (transport_charge >= 0),
  other_charge DECIMAL(12,2) NOT NULL DEFAULT 0
    CHECK (other_charge >= 0),
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE purchasing_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  batch_id UUID NOT NULL REFERENCES purchase_batches(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES products(id),
  weight_kg DECIMAL(12,3) NOT NULL CHECK (weight_kg > 0),
  rate_per_kg DECIMAL(12,2) NOT NULL CHECK (rate_per_kg >= 0),
  amount DECIMAL(14,2) GENERATED ALWAYS AS
    (ROUND(weight_kg * rate_per_kg, 2)) STORED,
  labour_total DECIMAL(12,2) NOT NULL DEFAULT 0
    CHECK (labour_total >= 0),
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

Do not add purchasing source or batch charges to `inventory_records`.
`purchasing_items` references only `batch_id`, not `record_id`. The old
`inventory_items` table and good-stock fields are not reused.

## API Shape
Notebook create/update accepts nested batches:

```json
{
  "purchase_batches": [
    {
      "id": "optional-batch-uuid",
      "source": "om",
      "transport_charge": 500,
      "other_charge": 200,
      "items": [
        {
          "id": "optional-item-uuid",
          "product_id": "product-uuid",
          "weight_kg": 50,
          "rate_per_kg": 30,
          "labour_total": 100
        }
      ]
    }
  ]
}
```

The server computes line amounts and returns `items_total`, `labour_total`,
`batch_total`, and the notebook purchasing total. CRUD is transactional and
rejects writes when the parent notebook is finalized.

## Release Acceptance
- Multiple Om and Quicklo batches can coexist on one day.
- Draft CRUD, dashboard, reports, PDF, and CSV all use the batch hierarchy.
- Display and export labels state kg, rate/kg, and labour total.
- No stock availability check is performed.
