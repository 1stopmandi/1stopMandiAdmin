# Workflow — Inventory Management System

## 1. Inventory Record Lifecycle

```mermaid
stateDiagram-v2
    [*] --> Draft: Admin creates record
    Draft --> Draft: Admin edits (add/remove/update items)
    Draft --> Finalized: Admin finalizes
    Finalized --> Draft: Admin un-finalizes
    Draft --> SoftDeleted: Admin deletes
    Finalized --> SoftDeleted: Admin deletes
    SoftDeleted --> Draft: Admin restores
    SoftDeleted --> [*]: Permanently purged (future/admin only)
```

---

## 2. Create Record Workflow

```mermaid
flowchart TD
    A[Admin opens Inventory module] --> B[Taps '+ New Record']
    B --> C[Fill Header: Title, Date, Purchased By]
    C --> D[Tap '+ Add Product']
    D --> E[Select product from catalogue]
    E --> F[Enter quantities: Purchased, Good, Recoverable, Waste]
    F --> G{Qty Balance OK?}
    G -->|Yes| H[Row shows green checkmark]
    G -->|No| I[Row shows red error with difference]
    I --> F
    H --> J{Add more products?}
    J -->|Yes| D
    J -->|No| K[Tap 'Save Record']
    K --> L{All rows valid?}
    L -->|Yes| M[POST /api/inventory]
    L -->|No| N[Show error: Fix highlighted rows]
    N --> F
    M --> O{API Success?}
    O -->|Yes| P[Navigate to record list + success toast]
    O -->|No| Q[Show server error message]
    Q --> F
```

---

## 3. Edit Record Workflow

```mermaid
flowchart TD
    A[Admin opens existing record] --> B{Record status?}
    B -->|Draft| C[Edit mode enabled]
    B -->|Finalized| D[View-only mode]
    D --> E{Admin taps 'Edit'?}
    E -->|Yes| F[Un-finalize confirmation]
    F --> C
    E -->|No| G[Stay in view mode]
    
    C --> H[Modify header fields]
    C --> I[Add/remove/edit product rows]
    I --> J{Qty balance check}
    J -->|Pass| K[Row valid]
    J -->|Fail| L[Show inline error]
    
    K --> M[Tap 'Save']
    M --> N[PUT /api/inventory/:id]
    N --> O[Record updated + totals recomputed]
```

---

## 4. Validation Workflow

### Client-Side (Flutter — Real-time)

```mermaid
flowchart TD
    A[User changes any qty field] --> B[Debounce 100ms]
    B --> C[Calculate: good_stock + recoverable + final_waste]
    C --> D{Sum == purchased_qty?}
    D -->|Yes| E[Show ✓ green indicator]
    D -->|No| F[Show ✗ red indicator + difference]
    
    E --> G[Check ALL rows]
    F --> G
    G --> H{All rows valid AND at least 1 row?}
    H -->|Yes| I[Enable Save button]
    H -->|No| J[Disable Save button]
```

### Server-Side (Backend — On Save)

```mermaid
flowchart TD
    A[Receive POST/PUT request] --> B[Validate header fields]
    B --> C{Header valid?}
    C -->|No| D[Return 400 VALIDATION_ERROR]
    C -->|Yes| E[Validate each item]
    
    E --> F{For each item:}
    F --> G[product_id exists?]
    F --> H[purchased_qty > 0?]
    F --> I[good_stock >= 0, recoverable >= 0, waste >= 0?]
    F --> J[purchased == good + recoverable + waste?]
    F --> K[No duplicate product_id?]
    
    G & H & I & J & K --> L{All pass?}
    L -->|No| M[Return 400 with per-item errors]
    L -->|Yes| N[Proceed with save]
```

---

## 5. Delete Workflow

```mermaid
flowchart TD
    A[Admin taps Delete on record] --> B[Show confirmation dialog]
    B --> C{Confirmed?}
    C -->|No| D[Cancel, no action]
    C -->|Yes| E[DELETE /api/inventory/:id]
    E --> F[Set deleted_at = NOW]
    F --> G[Log to audit_logs]
    G --> H[Record disappears from list]
    H --> I[Can be restored by admin if needed]
```

---

## 6. Reporting Workflow

```mermaid
flowchart TD
    A[Admin opens Reports] --> B[Select date range]
    B --> C[Select report type]
    C --> D[GET /api/inventory/reports/:type]
    D --> E[Display data table on screen]
    E --> F{Export?}
    F -->|PDF| G[GET /api/inventory/reports/export?format=pdf]
    F -->|Excel| H[GET /api/inventory/reports/export?format=excel]
    F -->|CSV| I[GET /api/inventory/reports/export?format=csv]
    G & H & I --> J[Download file]
```

---

## 7. Data Flow (End-to-End)

```mermaid
flowchart LR
    subgraph "Warehouse"
        W1[Staff buys from mandi]
        W2[Brings stock to warehouse]
        W3[Sorting session begins]
    end

    subgraph "Admin Panel"
        A1[Creates new record]
        A2[Adds each product]
        A3[Enters sorted quantities]
        A4[Saves record]
    end

    subgraph "Backend"
        B1[Validates qty balance]
        B2[Saves to PostgreSQL]
        B3[Recomputes totals]
        B4[Logs audit entry]
    end

    subgraph "Outputs"
        O1[Dashboard metrics update]
        O2[Reports available]
        O3[Historical data preserved]
    end

    W1 --> W2 --> W3 --> A1 --> A2 --> A3 --> A4 --> B1 --> B2 --> B3 --> B4 --> O1 & O2 & O3
```

---

## 8. Quantity Balance — The Core Business Rule

This is the single most important validation in the system:

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│   PURCHASED QTY  =  GOOD STOCK  +  RECOVERABLE  +  FINAL WASTE │
│                                                                 │
│   This is a PHYSICAL CONSTRAINT:                                │
│   What comes in MUST be fully accounted for after sorting.      │
│                                                                 │
│   200 kg of potatoes purchased:                                 │
│   → 180 kg fresh and sellable          (Good Stock)            │
│   → 15 kg slightly damaged but usable  (Recoverable)           │
│   → 5 kg rotten/discarded              (Final Waste)           │
│   → 180 + 15 + 5 = 200  ✓                                     │
│                                                                 │
│   If it doesn't add up, either:                                │
│   - Sorting counts were wrong (re-count)                       │
│   - Purchased qty was wrong (re-verify with vendor slip)       │
│   - The system should NOT save invalid data                    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

**Enforcement layers:**
1. Flutter UI — real-time visual feedback (green/red)
2. Flutter UI — Save button disabled if any row invalid
3. Backend — Validation middleware rejects request
4. Database — CHECK constraint as final safety net

---

## 9. Concurrent Edit Handling

**Current approach (Phase 1):** Last write wins with `updated_at` check.

```mermaid
sequenceDiagram
    participant Admin1
    participant Admin2
    participant Server
    participant DB

    Admin1->>Server: GET /inventory/abc (loads record)
    Admin2->>Server: GET /inventory/abc (loads same record)
    
    Admin1->>Server: PUT /inventory/abc (updated_at: T1)
    Server->>DB: UPDATE ... WHERE id = 'abc' AND updated_at = T1
    DB-->>Server: 1 row affected ✓
    Server-->>Admin1: 200 OK (new updated_at: T2)
    
    Admin2->>Server: PUT /inventory/abc (updated_at: T1)
    Server->>DB: UPDATE ... WHERE id = 'abc' AND updated_at = T1
    DB-->>Server: 0 rows affected (T1 is stale!)
    Server-->>Admin2: 409 CONFLICT "Record was modified by another user"
```

**Future (Phase 2+):** Real-time collaboration with WebSocket locks.

---

## 10. Audit Trail

Every significant action creates an audit log entry:

| Action | What's Logged |
|--------|---------------|
| Create record | Full record + items snapshot |
| Update header | Old values → New values |
| Add item | New item details |
| Update item | Old qty → New qty |
| Remove item | Removed item details |
| Delete record | Record ID + who + when |
| Restore record | Record ID + who + when |
| Finalize | Status change + who + when |

**Audit log query:**
```sql
SELECT * FROM audit_logs 
WHERE entity_type = 'inventory_record' 
  AND entity_id = :record_id
ORDER BY performed_at DESC;
```

---

## 11. Edge Cases

| Scenario | Handling |
|----------|----------|
| Product deleted from catalogue after being used in records | FK constraint prevents deletion; product deactivated instead |
| Employee marked as "left" but is referenced in old records | Record keeps `purchased_by_name` (denormalized); still viewable |
| Very large record (100+ products) | Paginate items in API? No — max ~100 products exist; always return all |
| Decimal quantities (0.5 kg) | DECIMAL(10,2) supports this; UI shows 2 decimal places |
| Zero purchased with some good stock | CHECK constraint rejects: purchased must be > 0 |
| All waste, no good stock | Valid: purchased=100, good=0, recoverable=0, waste=100 |
| Record for today vs past dates | Both allowed; future dates blocked |
| Duplicate records same title + date | Allowed — different sorting sessions can have same title |
| Network failure mid-save | Transaction rollback; no partial data; retry from client |

---

## 12. Future Extensibility

The workflow is designed so these can be added **without changing the core create/edit flow**:

| Future Feature | Integration Point |
|----------------|------------------|
| **Purchase cost** | Add `unit_price` column to `inventory_items`; new field in product row UI |
| **Supplier** | Add `supplier_id` to `inventory_records` header; dropdown in form |
| **Packing** | New module that reads `good_stock` from inventory items; separate workflow |
| **Stock ledger** | Background job that aggregates `good_stock` by product after finalization |
| **Approval** | Add `approved_by`, `approved_at` to records; new status: `pending_approval` |
| **Photos** | Separate attachments table; upload button on record |
| **Barcode scan** | Alternative product selection method in the "Add Product" flow |
| **Multi-warehouse** | Add `warehouse_id` to records; filter by warehouse in list |
| **Returns** | New `record_type` field: 'purchase', 'return', 'adjustment' |
