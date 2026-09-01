# Damage Section — Spec

## Behavior
Each damage row independently identifies whether the damage belongs to `om` or
`quicklo`. The product picker selects Om or Quicklo once and applies it to every
product added in that action; individual rows remain editable afterward.

A row records product, damaged kg, recovered kg, and calculated waste:
`waste_kg = damaged_kg - recovered_kg`.

Recovered damage is informational for reporting only. It does not add stock,
offset dispatch, or create any other stock movement. The notebook performs no
stock availability enforcement.

## UI
Damage is an accordion section. Each row contains:
- product;
- attribution: Om or Quicklo;
- damaged quantity (kg);
- recovered quantity (kg);
- read-only waste quantity (kg).

The section shows totals for damaged, recovered, and waste quantities. Drafts
may omit damage entirely. Finalized notebooks are read-only until unfinalized.

## SQL Shape
```sql
CREATE TABLE damage_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  record_id UUID NOT NULL REFERENCES inventory_records(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES products(id),
  attributed_to VARCHAR(20) NOT NULL
    CHECK (attributed_to IN ('om', 'quicklo')),
  damaged_kg DECIMAL(12,3) NOT NULL CHECK (damaged_kg > 0),
  recovered_kg DECIMAL(12,3) NOT NULL DEFAULT 0
    CHECK (recovered_kg >= 0 AND recovered_kg <= damaged_kg),
  waste_kg DECIMAL(12,3) GENERATED ALWAYS AS
    (damaged_kg - recovered_kg) STORED,
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

This table replaces the damage meaning previously mixed into
`inventory_items.good_stock`, `recoverable`, and `final_waste`. Those legacy
fields are not reused and no alternative migration model is supported.

## API Shape
```json
{
  "damage_items": [
    {
      "id": "optional-item-uuid",
      "product_id": "product-uuid",
      "attributed_to": "quicklo",
      "damaged_kg": 10,
      "recovered_kg": 3
    }
  ]
}
```

The server computes `waste_kg` and returns damaged, recovered, and waste totals.
It rejects negative values, recovered quantities above damaged quantities, and
writes to finalized notebooks.

## Release Acceptance
- Attribution can differ from one damage row to the next.
- Dashboard, reports, PDF, and CSV show all three kg totals by attribution.
- Recovered values remain informational in every calculation and export.
- Damage entries do not read or update stock balances.
