# Payroll Workflow — Employee Management System

## 1. Salary Generation Lifecycle

```
┌────────────────┐      ┌────────────────┐      ┌────────────────┐      ┌────────────────┐
│   GENERATED    │─────>│    PARTIAL     │─────>│      PAID      │      │   CANCELLED    │
│                │      │                │      │                │      │                │
│ Salary computed│      │ Some payment   │      │ Fully settled  │      │ Voided/Error   │
│ Not yet paid   │      │ made           │      │                │      │                │
└────────────────┘      └────────────────┘      └────────────────┘      └────────────────┘
        │                                                                        ▲
        └────────────────────────────────────────────────────────────────────────┘
                              (Admin cancels before any payment)
```

---

## 2. Complete Payroll Flow

### Phase 1: Salary Generation

```
Admin selects date range
        │
        ▼
┌─────────────────────────────────────────┐
│ Validate:                                │
│ - period_start < period_end              │
│ - No overlap with existing periods       │
│ - All days in range have attendance      │
│   (warn if unmarked days exist)          │
└────────────────────┬────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────┐
│ For each active employee:                │
│                                          │
│ 1. Get monthly_salary from employee      │
│ 2. Calculate daily_wage:                 │
│    = monthly_salary / days_in_month      │
│                                          │
│ 3. Query attendance for date range:      │
│    COUNT present, half_day, absent,      │
│    leave, holiday                         │
│                                          │
│ 4. Calculate payable_days:               │
│    = present×1 + half_day×0.5            │
│      + holiday×1 + leave×multiplier      │
│                                          │
│ 5. Calculate gross_salary:               │
│    = daily_wage × payable_days           │
│                                          │
│ 6. Get previous_pending:                 │
│    = SUM of unpaid from prior periods    │
│                                          │
│ 7. Get advances (future):               │
│    = 0 for now                           │
│                                          │
│ 8. Calculate final_payable:              │
│    = gross + previous_pending - advances │
└────────────────────┬────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────┐
│ Show PREVIEW to admin:                   │
│                                          │
│ ┌─────────────────────────────────────┐ │
│ │ Employee │ Daily │ Days │ Gross │ Pay│ │
│ │ Raju     │ 677   │ 26.0 │17612 │17612│
│ │ Suresh   │ 580   │ 25.5 │14790 │14790│
│ │ ...      │       │      │      │     │ │
│ └─────────────────────────────────────┘ │
│                                          │
│ [Confirm & Generate]    [Cancel]         │
└────────────────────┬────────────────────┘
                     │ Admin confirms
                     ▼
┌─────────────────────────────────────────┐
│ Create salary_period records             │
│ Status = 'generated'                     │
│ Create audit_log entries                 │
└─────────────────────────────────────────┘
```

---

### Phase 2: Payment / Settlement

```
Admin opens salary settlement screen
        │
        ▼
┌─────────────────────────────────────────┐
│ List salary periods with status:         │
│ 'generated' or 'partial'                 │
│                                          │
│ Shows:                                   │
│ - Employee name                          │
│ - Period dates                           │
│ - Final payable                          │
│ - Amount already paid                    │
│ - Remaining balance                      │
└────────────────────┬────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────┐
│ Admin selects employee(s) to pay         │
│                                          │
│ For each:                                │
│ - Enter amount (default: full remaining) │
│ - Select payment method (Cash/UPI/Bank)  │
│ - Enter transaction reference (optional) │
│ - Add notes (optional)                   │
└────────────────────┬────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────┐
│ Validate:                                │
│ - amount <= remaining balance            │
│ - payment_method is valid                │
│ - salary_period status != 'paid'         │
└────────────────────┬────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────┐
│ BEGIN TRANSACTION                        │
│                                          │
│ 1. INSERT into salary_payments           │
│ 2. Calculate total_paid for this period  │
│ 3. IF total_paid >= final_payable:       │
│      UPDATE salary_period status = 'paid'│
│    ELSE:                                 │
│      UPDATE status = 'partial'           │
│ 4. INSERT audit_log                      │
│                                          │
│ COMMIT                                   │
└─────────────────────────────────────────┘
```

---

### Phase 3: Employee Exit Settlement

```
Admin marks employee status = 'left'
        │
        ▼
┌─────────────────────────────────────────┐
│ System checks:                           │
│ - Any unsettled salary periods?          │
│ - Any attendance not yet in a period?    │
└────────────────────┬────────────────────┘
                     │
          ┌──────────┼──────────┐
          │                     │
     Has pending           No pending
          │                     │
          ▼                     ▼
┌──────────────────┐   ┌──────────────────┐
│ Show warning:     │   │ Mark as 'left'    │
│ "₹X pending.     │   │ Employee inactive │
│  Generate final   │   │ Records preserved │
│  salary first?"   │   └──────────────────┘
└────────┬─────────┘
         │ Admin generates final salary
         ▼
┌─────────────────────────────────────────┐
│ Generate salary from last settled date   │
│ to last working day                      │
│                                          │
│ Include:                                 │
│ - Previous pending from older periods    │
│ - Current period calculation             │
│                                          │
│ Admin pays final amount                  │
└────────────────────┬────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────┐
│ Employee status = 'left'                 │
│ All records preserved                    │
│ Employee visible in reports forever      │
│ Not shown in active employee lists       │
└─────────────────────────────────────────┘
```

---

## 3. Payment Types

### Full Payment
- amount_paid = remaining balance
- salary_period.status → `paid`
- Most common case

### Partial Payment
- amount_paid < remaining balance
- salary_period.status → `partial`
- Remaining carries forward
- Multiple partial payments allowed

### Example: Partial Payment Flow
```
Salary Period: ₹21,000 final payable

Payment 1: ₹10,000 (Cash) on July 16
  → status = 'partial', remaining = ₹11,000

Payment 2: ₹5,000 (UPI) on July 20
  → status = 'partial', remaining = ₹6,000

Payment 3: ₹6,000 (Bank) on July 25
  → status = 'paid', remaining = ₹0
```

---

## 4. Previous Pending Calculation

```sql
-- For a given employee, pending amount from ALL prior periods
SELECT 
  COALESCE(SUM(sp.final_payable), 0) - COALESCE(SUM(pay.total_paid), 0) AS previous_pending
FROM salary_periods sp
LEFT JOIN (
  SELECT salary_period_id, SUM(amount_paid) as total_paid
  FROM salary_payments
  GROUP BY salary_period_id
) pay ON pay.salary_period_id = sp.id
WHERE sp.employee_id = :employee_id
  AND sp.status IN ('generated', 'partial')
  AND sp.period_end < :current_period_start;
```

---

## 5. Salary Recalculation Scenarios

| Trigger | Action |
|---------|--------|
| Attendance modified for a day within an open period | Recalculate that salary period |
| Employee monthly_salary changed | Does NOT retroactively change existing periods |
| Salary period cancelled | Amounts are reversed; pending recalculated |
| Holiday added retroactively | Recalculate affected open periods |

---

## 6. Multi-Month Period Handling

When a salary period spans multiple months (unusual but possible):
```
Period: 25 June → 10 July

Calculation:
- June portion (25-30): daily_wage = monthly_salary / 30 (June has 30 days)
  payable_days_june = attendance in 25-30 June
  gross_june = daily_wage_june × payable_days_june

- July portion (1-10): daily_wage = monthly_salary / 31 (July has 31 days)
  payable_days_july = attendance in 1-10 July
  gross_july = daily_wage_july × payable_days_july

total_gross = gross_june + gross_july
```

**Recommendation:** For simplicity in Phase 1, restrict periods to within a single calendar month. Show a warning if admin tries to cross months.

---

## 7. Transaction Safety

All payment operations use database transactions:

```
BEGIN;
  -- Lock the salary_period row
  SELECT * FROM salary_periods WHERE id = :id FOR UPDATE;
  
  -- Verify remaining balance
  SELECT COALESCE(SUM(amount_paid), 0) as paid 
  FROM salary_payments WHERE salary_period_id = :id;
  
  -- Ensure amount doesn't exceed remaining
  -- Insert payment
  INSERT INTO salary_payments (...) VALUES (...);
  
  -- Update salary_period status
  UPDATE salary_periods SET status = :new_status WHERE id = :id;
COMMIT;
```

This prevents race conditions (two admins paying the same salary simultaneously).

---

## 8. Salary Settlement Screen Data

| Column | Source |
|--------|--------|
| Employee Name | employees.full_name |
| Employee Code | employees.employee_code |
| Daily Wage | Computed: monthly_salary / days_in_month |
| Present Days | COUNT from attendance WHERE status = 'present' |
| Half Days | COUNT from attendance WHERE status = 'half_day' |
| Absent Days | COUNT from attendance WHERE status = 'absent' |
| Working Hours | SUM(total_working_hours) from attendance |
| Gross Salary | daily_wage × payable_days |
| Previous Pending | SUM of unpaid from prior periods |
| Advances | 0 (future feature) |
| Final Payable | gross + pending - advances |
| Amount Paid | SUM from salary_payments for this period |
| Remaining | final_payable - amount_paid |

---

## 9. Reporting Queries

### Payroll Summary for Month
```sql
SELECT 
  e.employee_code,
  e.full_name,
  e.designation,
  sp.period_start,
  sp.period_end,
  sp.daily_wage,
  sp.present_days,
  sp.half_days,
  sp.absent_days,
  sp.gross_salary,
  sp.final_payable,
  sp.status,
  COALESCE(SUM(pay.amount_paid), 0) as total_paid,
  sp.final_payable - COALESCE(SUM(pay.amount_paid), 0) as remaining
FROM salary_periods sp
JOIN employees e ON e.id = sp.employee_id
LEFT JOIN salary_payments pay ON pay.salary_period_id = sp.id
WHERE sp.period_start >= '2025-07-01'
  AND sp.period_end <= '2025-07-31'
GROUP BY sp.id, e.id
ORDER BY e.full_name;
```
