# Attendance Workflow — Employee Management System

## 1. Attendance Lifecycle

```
┌─────────────┐     Admin opens      ┌──────────────────┐
│  Day Starts │ ──── attendance ────> │  Attendance Page  │
└─────────────┘     screen            └────────┬─────────┘
                                               │
                                    System loads all active
                                    employees for today
                                               │
                                               ▼
                                    ┌──────────────────┐
                                    │  Mark Attendance  │
                                    │  for each employee│
                                    └────────┬─────────┘
                                               │
                              ┌─────────────────┼─────────────────┐
                              │                 │                   │
                              ▼                 ▼                   ▼
                      ┌───────────┐    ┌───────────┐      ┌───────────┐
                      │  Present  │    │ Half Day  │      │  Absent   │
                      │  (1 day)  │    │ (0.5 day) │      │  (0 day)  │
                      └─────┬─────┘    └─────┬─────┘      └─────┬─────┘
                            │                │                   │
                            ▼                ▼                   ▼
                    ┌─────────────────────────────────────────────────┐
                    │  Auto-calculate working hours (if times given)  │
                    │  working_hours = check_out - check_in           │
                    └──────────────────────┬──────────────────────────┘
                                           │
                                           ▼
                    ┌─────────────────────────────────────────────────┐
                    │  Save attendance record                          │
                    │  UNIQUE(employee_id, date) — upsert if exists   │
                    └──────────────────────┬──────────────────────────┘
                                           │
                                           ▼
                    ┌─────────────────────────────────────────────────┐
                    │  If open salary period exists for this date:     │
                    │  Mark salary period for recalculation            │
                    └─────────────────────────────────────────────────┘
```

---

## 2. Daily Attendance Flow (Admin Perspective)

### Step 1: Open Attendance Screen
- System loads today's date (changeable to past dates up to 7 days)
- Fetches all active employees
- Shows attendance already marked (if any) with ability to edit

### Step 2: Mark Each Employee
Admin selects status for each employee:
| Status | Payable Days | Working Hours |
|--------|-------------|---------------|
| Present | 1.0 | Calculated from check-in/out |
| Half Day | 0.5 | Calculated from check-in/out |
| Absent | 0.0 | 0 |
| Leave | Configurable (default 0) | 0 |
| Holiday | 1.0 (all employees) | 0 |

### Step 3: Optional Time Entry
- Check-in and check-out times are optional
- If provided, working hours auto-calculate
- If not provided, working hours remain null (not 0)

### Step 4: Bulk Save
- All attendance records saved in a single transaction
- Uses UPSERT: if record exists for (employee, date) → update; else → insert
- Returns confirmation with summary

---

## 3. Attendance Modification Rules

| Scenario | Allowed? | Condition |
|----------|----------|-----------|
| Mark today's attendance | Yes | Always |
| Mark yesterday's attendance | Yes | Always |
| Modify past attendance (< 7 days) | Yes | If salary not yet `paid` |
| Modify past attendance (> 7 days) | No | Locked after 7 days |
| Modify attendance with paid salary | No | Salary period is `paid` |
| Mark future date | No | Never allowed |
| Mark for inactive/left employee | No | Employee must be `active` |
| Mark holiday for all | Yes | Batch operation |

---

## 4. Working Hours Calculation

```
IF check_in_time AND check_out_time are provided:
    total_working_hours = check_out_time - check_in_time (in decimal hours)
    
    Example: 
    check_in = 09:00, check_out = 18:00
    total_working_hours = 9.0
    
    check_in = 09:00, check_out = 13:30
    total_working_hours = 4.5
    
ELSE:
    total_working_hours = NULL (not tracked for this day)
```

---

## 5. Salary Calculation Flow

### Formula
```
days_in_month = number of calendar days in the salary period's month
daily_wage = monthly_salary / days_in_month

payable_days = present_days × 1.0
             + half_days × 0.5
             + holiday_days × 1.0
             + leave_days × leave_multiplier  (default 0, configurable later)

gross_salary = daily_wage × payable_days

final_payable = gross_salary + previous_pending - advances
```

### Calculation Example
```
Employee: Raju Kumar
Monthly Salary: ₹21,000
Period: 1 July 2025 → 31 July 2025
Days in July: 31

Daily Wage = 21000 / 31 = ₹677.42

Attendance in period:
- Present: 24 days
- Half Day: 2 days
- Absent: 3 days
- Leave: 1 day
- Holiday: 1 day (Independence Day)

Payable Days = 24×1.0 + 2×0.5 + 1×1.0 + 0 = 26.0 days

Gross Salary = 677.42 × 26.0 = ₹17,612.90

Previous Pending: ₹0
Advances: ₹0

Final Payable = ₹17,612.90
```

---

## 6. Salary Recalculation Trigger

When attendance is modified (PUT /api/attendance/:id):

```
1. Find any salary_period where:
   - employee_id matches
   - period_start <= attendance.date <= period_end
   - status IN ('generated', 'partial')

2. If found:
   - Re-query attendance for that period's date range
   - Recalculate present_days, half_days, absent_days, etc.
   - Recalculate gross_salary and final_payable
   - Update the salary_period record

3. If salary_period status = 'paid':
   - REJECT the attendance modification
   - Return error: ATTENDANCE_LOCKED
```

---

## 7. Edge Cases

### 7.1 Employee Joins Mid-Month
- Salary period starts from `joining_date`, not month start
- Days in month still uses calendar month days for daily wage calculation
- Only attendance from joining date onwards counts

### 7.2 Employee Leaves Mid-Month
- Salary period ends on last working day
- Final salary calculated up to that date
- Remaining days are not counted as absent

### 7.3 No Attendance Marked
- Days without attendance records are treated as "unmarked" (not absent)
- Salary generation warns about unmarked days
- Admin must explicitly mark absent — system never auto-marks

### 7.4 Overlapping Salary Periods
- Not allowed. API rejects if any day in the requested range already has a salary period
- Example: If 1-15 July is generated, cannot generate 10-31 July (overlap on 10-15)

### 7.5 Holiday Marking
- Holidays apply to ALL active employees on that date
- Admin marks a date as holiday → all active employees get status = 'holiday'
- Individual employees can override (if they were absent on a holiday)

### 7.6 Backdated Attendance
- Allowed up to 7 days back
- Beyond 7 days: only super-admin (future role) can modify
- Always creates audit log entry

### 7.7 Decimal Working Hours
- Stored as DECIMAL(4,2)
- 8 hours 30 minutes = 8.50
- 4 hours 15 minutes = 4.25
- Rounded to nearest 0.25 (optional, configurable)

---

## 8. Attendance Status Transitions

```
┌──────────┐
│ Unmarked │ (default — no record exists)
└────┬─────┘
     │ Admin marks attendance
     ▼
┌──────────────────────────────────────────────┐
│ Present | Half Day | Absent | Leave | Holiday │
└────┬─────────────────────────────────────────┘
     │ Admin edits (within 7 days, salary not paid)
     ▼
┌──────────────────────────────────────────────┐
│ Any other valid status                        │
└────┬─────────────────────────────────────────┘
     │ Salary period marked as 'paid'
     ▼
┌──────────┐
│  LOCKED  │ (no further modifications)
└──────────┘
```
