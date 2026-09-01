# Dispatch Section — Spec

## Behavior
Each dispatch row records a product, pocket count, destination,
total row weight in kg, and rate per kg. Amount is `weight × rate`.

Weight is not per pocket. The notebook records kg only and does not reserve,
decrement, or validate available stock.

Drafts may omit dispatch or contain only a subset of notebook sections. Every
persisted dispatch row must be valid.

## UI
Dispatch is an accordion section with add/remove row controls and a read-only
total. Each row contains:
- product;
- pocket count;
- total weight (kg);
- rate (₹/kg);
- calculated amount;
- free-text destination, entered once while adding products and applied to every
  product added in that action.

Dispatch does not fetch clients. A finalized notebook is read-only until
unfinalized.

## SQL Shape
```sql
CREATE TABLE dispatch_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  record_id UUID NOT NULL REFERENCES inventory_records(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES products(id),
  dispatch_to VARCHAR(100) NOT NULL CHECK (length(trim(dispatch_to)) > 0),
  pocket INTEGER NOT NULL DEFAULT 0 CHECK (pocket >= 0),
  weight DECIMAL(12,2) NOT NULL CHECK (weight > 0),
  rate DECIMAL(12,2) NOT NULL CHECK (rate >= 0),
  amount DECIMAL(14,2) GENERATED ALWAYS AS (weight * rate) STORED,
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (record_id, product_id, dispatch_to)
);
```

## API Shape
```json
{
  "dispatch_items": [
    {
      "id": "optional-item-uuid",
      "product_id": "product-uuid",
      "dispatch_to": "Main warehouse",
      "pocket": 5,
      "weight": 25,
      "rate": 45
    }
  ]
}
```

The response includes the destination, calculated line amount, and total
dispatch amount. CRUD rejects writes to finalized notebooks.

## Release Acceptance
- No client API or client table lookup is used.
- Reports, dashboard, PDF, and CSV use total row weight and calculated amount.
- Exports label weight as kg and rate as per kg.
- Dispatch succeeds without a stock availability check.
