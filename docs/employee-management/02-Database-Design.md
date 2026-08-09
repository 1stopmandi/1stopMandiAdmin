# Database Design — Employee Management System

## 1. ER Diagram

```
┌─────────────────────┐       ┌─────────────────────────┐
│     employees       │       │      attendance          │
├─────────────────────┤       ├─────────────────────────┤
│ id (PK, UUID)       │──┐    │ id (PK, UUID)           │
│ employee_code       │  │    │ employee_id (FK)        │──┐
│ full_name           │  │    │ date                    │  │
│ mobile_number       │  │    │ check_in_time           │  │
│ alternate_number    │  │    │ check_out_time          │  │
│ address             │  │    │ status                  │  │
│ aadhaar_number      │  │    │ total_working_hours     │  │
│ photo_url           │  │    │ shift_id (FK, nullable) │  │
│ emergency_contact   │  │    │ notes                   │  │
│ joining_date        │  │    │ marked_by (FK)          │  │
│ status              │  │    │ created_at              │  │
│ employee_type       │  │    │ updated_at              │  │
│ designation         │  │    └─────────────────────────┘  │
│ monthly_salary      │  │                                  │
│ notes               │  │    ┌─────────────────────────┐  │
│ deleted_at          │  │    │   salary_periods        │  │
│ created_at          │  │    ├─────────────────────────┤  │
│ updated_at          │  └───>│ id (PK, UUID)           │  │
│ created_by          │       │ employee_id (FK)        │──┘
│ updated_by          │       │ period_start            │
└─────────────────────┘       │ period_end              │
                              │ daily_wage              │
                              │ present_days            │
                              │ half_days               │
                              │ absent_days             │
                              │ leave_days              │
                              │ holiday_days            │
                              │ total_working_hours     │
                              │ gross_salary            │
                              │ previous_pending        │
                              │ advances                │
                              │ final_payable           │
                              │ status                  │
                              │ created_at              │
                              │ updated_at              │
                              └──────────┬──────────────┘
                                         │
                              ┌──────────┴──────────────┐
                              │   salary_payments       │
                              ├─────────────────────────┤
                              │ id (PK, UUID)           │
                              │ salary_period_id (FK)   │
                              │ amount_paid             │
                              │ payment_method          │
                              │ payment_date            │
                              │ paid_by (FK)            │
                              │ transaction_reference   │
                              │ notes                   │
                              │ created_at              │
                              └─────────────────────────┘

┌─────────────────────┐
│   shifts (future)   │
├─────────────────────┤
│ id (PK, UUID)       │
│ name                │
│ start_time          │
│ end_time            │
│ created_at          │
│ updated_at          │
└─────────────────────┘

┌─────────────────────┐
│   audit_logs        │
├─────────────────────┤
│ id (PK, UUID)       │
│ entity_type         │
│ entity_id           │
│ action              │
│ old_values (JSONB)  │
│ new_values (JSONB)  │
│ performed_by (FK)   │
│ performed_at        │
└─────────────────────┘
```

---

## 2. Table Definitions

### 2.1 `employees`

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | UUID | PK, DEFAULT gen_random_uuid() | Primary key |
| `employee_code` | VARCHAR(20) | UNIQUE, NOT NULL | Auto-generated (e.g., EMP-001) |
| `full_name` | VARCHAR(100) | NOT NULL | Employee full name |
| `mobile_number` | VARCHAR(15) | NOT NULL | Primary phone |
| `alternate_number` | VARCHAR(15) | NULL | Secondary phone |
| `address` | TEXT | NOT NULL | Full address |
| `aadhaar_number` | VARCHAR(12) | NULL | Encrypted at rest |
| `photo_url` | TEXT | NULL | S3 presigned URL path |
| `emergency_contact` | VARCHAR(15) | NOT NULL | Emergency phone number |
| `joining_date` | DATE | NOT NULL | Date of joining |
| `status` | ENUM | NOT NULL, DEFAULT 'active' | active, inactive, left |
| `employee_type` | ENUM | NOT NULL, DEFAULT 'daily_wage' | daily_wage, monthly, contract |
| `designation` | ENUM | NOT NULL | packing_staff, loader, helper, cleaner, warehouse_staff, other |
| `monthly_salary` | DECIMAL(10,2) | NOT NULL | Monthly salary amount in INR |
| `notes` | TEXT | NULL | Admin notes |
| `deleted_at` | TIMESTAMPTZ | NULL | Soft delete marker |
| `created_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Record creation |
| `updated_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Last update |
| `created_by` | UUID | FK → users.id | Who created |
| `updated_by` | UUID | FK → users.id | Who last updated |

**Indexes:**
- `idx_employees_status` — B-tree on `status` WHERE `deleted_at IS NULL`
- `idx_employees_designation` — B-tree on `designation`
- `idx_employees_code` — Unique on `employee_code`
- `idx_employees_mobile` — B-tree on `mobile_number`
- `idx_employees_name_search` — GIN trigram on `full_name` (for search)

---

### 2.2 `attendance`

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | UUID | PK | Primary key |
| `employee_id` | UUID | FK → employees.id, NOT NULL | Employee reference |
| `date` | DATE | NOT NULL | Attendance date |
| `check_in_time` | TIME | NULL | Clock in |
| `check_out_time` | TIME | NULL | Clock out |
| `status` | ENUM | NOT NULL | present, half_day, absent, leave, holiday |
| `total_working_hours` | DECIMAL(4,2) | NULL | Auto-calculated from check-in/out |
| `shift_id` | UUID | FK → shifts.id, NULL | Future shift support |
| `notes` | TEXT | NULL | Admin notes |
| `marked_by` | UUID | FK → users.id, NOT NULL | Who marked attendance |
| `created_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | |
| `updated_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | |

**Constraints:**
- UNIQUE(`employee_id`, `date`) — one attendance record per employee per day

**Indexes:**
- `idx_attendance_employee_date` — Unique composite on (`employee_id`, `date`)
- `idx_attendance_date` — B-tree on `date` (for daily reports)
- `idx_attendance_status` — B-tree on `status`
- `idx_attendance_employee_range` — B-tree on (`employee_id`, `date`) for range queries

---

### 2.3 `salary_periods`

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | UUID | PK | Primary key |
| `employee_id` | UUID | FK → employees.id, NOT NULL | Employee reference |
| `period_start` | DATE | NOT NULL | Salary period start |
| `period_end` | DATE | NOT NULL | Salary period end |
| `daily_wage` | DECIMAL(10,2) | NOT NULL | Computed: monthly_salary / days_in_month |
| `present_days` | DECIMAL(4,1) | NOT NULL, DEFAULT 0 | Count of present days |
| `half_days` | DECIMAL(4,1) | NOT NULL, DEFAULT 0 | Count of half days |
| `absent_days` | DECIMAL(4,1) | NOT NULL, DEFAULT 0 | Count of absent days |
| `leave_days` | DECIMAL(4,1) | NOT NULL, DEFAULT 0 | Count of leave days |
| `holiday_days` | DECIMAL(4,1) | NOT NULL, DEFAULT 0 | Count of holidays |
| `total_working_hours` | DECIMAL(6,2) | NULL | Sum of working hours |
| `gross_salary` | DECIMAL(10,2) | NOT NULL | daily_wage × payable_days |
| `previous_pending` | DECIMAL(10,2) | NOT NULL, DEFAULT 0 | Carried forward from prior period |
| `advances` | DECIMAL(10,2) | NOT NULL, DEFAULT 0 | Advance deductions (future) |
| `final_payable` | DECIMAL(10,2) | NOT NULL | gross + previous_pending - advances |
| `status` | ENUM | NOT NULL, DEFAULT 'generated' | generated, partial, paid, cancelled |
| `created_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | |
| `updated_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | |

**Constraints:**
- CHECK(`period_end >= period_start`)
- No overlapping periods for same employee (enforced via application logic + exclusion constraint)

**Indexes:**
- `idx_salary_periods_employee` — B-tree on `employee_id`
- `idx_salary_periods_dates` — B-tree on (`employee_id`, `period_start`, `period_end`)
- `idx_salary_periods_status` — B-tree on `status`

---

### 2.4 `salary_payments`

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | UUID | PK | Primary key |
| `salary_period_id` | UUID | FK → salary_periods.id, NOT NULL | Which salary period |
| `amount_paid` | DECIMAL(10,2) | NOT NULL | Amount of this payment |
| `payment_method` | ENUM | NOT NULL | cash, upi, bank_transfer |
| `payment_date` | DATE | NOT NULL | When payment was made |
| `paid_by` | UUID | FK → users.id, NOT NULL | Admin who processed |
| `transaction_reference` | VARCHAR(100) | NULL | UPI ref / bank txn ID |
| `notes` | TEXT | NULL | Payment notes |
| `created_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | |

**Indexes:**
- `idx_salary_payments_period` — B-tree on `salary_period_id`
- `idx_salary_payments_date` — B-tree on `payment_date`

**Note:** Salary payments are IMMUTABLE — no updates, no deletes. Corrections are handled by creating reversal entries.

---

### 2.5 `shifts` (Future — Table created but unused)

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | UUID | PK | Primary key |
| `name` | VARCHAR(50) | NOT NULL | e.g., "Morning", "Night" |
| `start_time` | TIME | NOT NULL | Shift start |
| `end_time` | TIME | NOT NULL | Shift end |
| `is_active` | BOOLEAN | DEFAULT true | |
| `created_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | |
| `updated_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | |

---

### 2.6 `audit_logs`

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | UUID | PK | Primary key |
| `entity_type` | VARCHAR(50) | NOT NULL | 'employee', 'attendance', 'salary_period', 'salary_payment' |
| `entity_id` | UUID | NOT NULL | ID of the affected record |
| `action` | VARCHAR(20) | NOT NULL | 'create', 'update', 'delete', 'restore' |
| `old_values` | JSONB | NULL | Previous state |
| `new_values` | JSONB | NULL | New state |
| `performed_by` | UUID | FK → users.id, NOT NULL | Who performed the action |
| `performed_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | When |

**Indexes:**
- `idx_audit_entity` — B-tree on (`entity_type`, `entity_id`)
- `idx_audit_performed_at` — B-tree on `performed_at`

---

## 3. Enum Definitions

```sql
CREATE TYPE employee_status AS ENUM ('active', 'inactive', 'left');
CREATE TYPE employee_type AS ENUM ('daily_wage', 'monthly', 'contract');
CREATE TYPE designation AS ENUM ('packing_staff', 'loader', 'helper', 'cleaner', 'warehouse_staff', 'other');
CREATE TYPE attendance_status AS ENUM ('present', 'half_day', 'absent', 'leave', 'holiday');
CREATE TYPE salary_period_status AS ENUM ('generated', 'partial', 'paid', 'cancelled');
CREATE TYPE payment_method AS ENUM ('cash', 'upi', 'bank_transfer');
```

---

## 4. Key Relationships

```
employees (1) ──── (N) attendance
employees (1) ──── (N) salary_periods
salary_periods (1) ──── (N) salary_payments
shifts (1) ──── (N) attendance  [future]
```

---

## 5. Indexing Strategy

| Query Pattern | Index |
|--------------|-------|
| List active employees | Partial index on `status` WHERE `deleted_at IS NULL` |
| Search by name | GIN trigram index for ILIKE queries |
| Attendance for date | Composite on (`date`) |
| Attendance for employee in range | Composite on (`employee_id`, `date`) |
| Salary periods for employee | B-tree on `employee_id` |
| Unpaid salaries | Composite on (`status`) WHERE `status != 'paid'` |
| Audit trail for entity | Composite on (`entity_type`, `entity_id`) |

---

## 6. Data Integrity Rules

1. **Attendance uniqueness**: One record per employee per day (unique constraint)
2. **Salary period non-overlap**: Application logic prevents overlapping periods for same employee
3. **Payment immutability**: No UPDATE/DELETE on `salary_payments` — only INSERT
4. **Soft delete cascade**: When employee soft-deleted, no attendance/salary records are touched
5. **Referential integrity**: All FKs use `ON DELETE RESTRICT` (never cascade deletes)
6. **Working hours**: Auto-calculated as `check_out_time - check_in_time` (nullable if times not provided)

---

## 7. Migration Strategy

Migrations are versioned and sequential:
```
migrations/
├── 001_create_employee_enums.sql
├── 002_create_employees_table.sql
├── 003_create_shifts_table.sql
├── 004_create_attendance_table.sql
├── 005_create_salary_periods_table.sql
├── 006_create_salary_payments_table.sql
├── 007_create_audit_logs_table.sql
└── 008_create_indexes.sql
```

Each migration is idempotent (IF NOT EXISTS) and has a corresponding rollback file.
