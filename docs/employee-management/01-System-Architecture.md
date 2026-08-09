# System Architecture — Employee Management System

## 1. Overview

The Employee Management System (EMS) is a new module within the **1StopMandi Admin Panel** that handles warehouse workforce management — from onboarding employees to tracking daily attendance, calculating salaries, and processing settlements.

```
┌─────────────────────────────────────────────────────────────────┐
│                     1StopMandi Admin Panel (Flutter)             │
├─────────────────────────────────────────────────────────────────┤
│  Features                                                       │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐          │
│  │ Employee │ │Attendance│ │  Salary  │ │ Reports  │          │
│  │   CRUD   │ │  Marking │ │Settlement│ │Dashboard │          │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘          │
│       │             │             │             │                │
│  ┌────┴─────────────┴─────────────┴─────────────┴────┐         │
│  │              Riverpod State Management             │         │
│  └────┬─────────────┬─────────────┬─────────────┬────┘         │
│       │             │             │             │                │
│  ┌────┴─────────────┴─────────────┴─────────────┴────┐         │
│  │           Repository Layer (Dio HTTP)              │         │
│  └────────────────────────┬──────────────────────────┘         │
└───────────────────────────┼─────────────────────────────────────┘
                            │ HTTPS (Bearer Token)
┌───────────────────────────┼─────────────────────────────────────┐
│                     Backend (Node.js / Express)                  │
├───────────────────────────┼─────────────────────────────────────┤
│  ┌────────────────────────┴──────────────────────────┐         │
│  │              REST API Router                        │         │
│  └────┬─────────────┬─────────────┬─────────────┬────┘         │
│       │             │             │             │                │
│  ┌────┴────┐  ┌─────┴────┐ ┌─────┴────┐ ┌─────┴────┐         │
│  │Employee │  │Attendance│ │  Salary  │ │  Report  │         │
│  │Service  │  │ Service  │ │ Service  │ │ Service  │         │
│  └────┬────┘  └────┬─────┘ └────┬─────┘ └────┬─────┘         │
│       │             │             │             │                │
│  ┌────┴─────────────┴─────────────┴─────────────┴────┐         │
│  │              PostgreSQL Database                    │         │
│  └────────────────────────────────────────────────────┘         │
└─────────────────────────────────────────────────────────────────┘
```

---

## 2. Architecture Principles

| Principle | Application |
|-----------|-------------|
| **Clean Architecture** | Separation into Presentation → State → Repository → API layers |
| **Feature-First Modules** | Each module lives in `lib/features/<module>/` |
| **SOLID** | Single responsibility services; interface-based repositories |
| **Soft Deletes** | All deletions set `deleted_at` timestamp; never hard-delete |
| **Audit Trail** | `created_at`, `updated_at`, `created_by`, `updated_by` on every table |
| **Transaction Safety** | Salary calculations wrapped in DB transactions |
| **Extensibility** | Shift support, contract types, advances — designed as nullable columns or separate tables |

---

## 3. Module Breakdown

### Module 1 — Employee Management
- CRUD operations for warehouse employees
- Soft delete with status transitions: Active → Inactive → Left
- Photo upload (optional, via S3/presigned URL)
- Search and filter by name, designation, status

### Module 2 — Daily Attendance
- Admin marks attendance per employee per day
- Tracks check-in/check-out times
- Auto-calculates working hours
- Statuses: Present, Half Day, Absent, Leave, Holiday

### Module 3 — Salary Management
- Auto-calculated from attendance data
- Formula: `Daily Wage = Monthly Salary / Days in Month`
- `Gross Salary = Daily Wage × Payable Days`
- Payable Days: Present = 1, Half Day = 0.5, Absent = 0, Leave = configurable
- Recalculates when attendance changes (event-driven or on-demand)

### Module 4 — Salary Settlement
- Generate salary for any date range
- Shows breakdown: present days, half days, working hours, gross, pending, advances
- Payment: Full / Partial with method (Cash, UPI, Bank Transfer)
- Immutable payment history

### Module 5 — Employee Exit
- Status transition to "Left"
- Auto-calculates pending salary
- After final settlement → Employee becomes inactive
- All records preserved permanently

### Module 6 — Reports
- Daily/Monthly attendance reports
- Salary and pending salary reports
- Employee history
- Export: PDF, Excel, CSV

### Module 7 — Dashboard
- Real-time metrics: total employees, present today, absent, unmarked
- Salary pending vs paid this month
- Attendance percentage

---

## 4. Design Decisions

### 4.1 Why Separate Salary Table from Attendance?
Attendance is a daily fact (immutable once day ends). Salary is a computed aggregate for a date range. Separating them allows:
- Re-calculation without mutating attendance records
- Multiple salary periods (bi-weekly, custom ranges)
- Clear audit trail on payments

### 4.2 Why Monthly Salary stored on Employee (not just Daily Wage)?
Business requirement: employees are hired at a monthly rate. Daily wage is derived:
```
daily_wage = monthly_salary / days_in_month
```
This changes month to month (28, 30, 31 days), so we store the monthly rate and compute daily dynamically.

### 4.3 Why No Shift Table Yet?
Current business has no shifts. The schema includes a nullable `shift_id` FK on `attendance` table so shifts can be added later without migration headaches.

### 4.4 Why Soft Delete?
- Legal compliance (labor records)
- Historical reporting accuracy
- Salary records reference employee IDs forever
- Easy "undo" for accidental deactivation

### 4.5 Why Event-Driven Salary Recalculation?
When attendance is modified (e.g., correcting yesterday's entry), any open (unsettled) salary period for that employee should reflect the change. This is handled by:
1. Backend recalculates on salary fetch (pull-based, simpler)
2. OR triggers a recalc job on attendance save (push-based, future)

For Phase 1, we use **pull-based** (calculate on GET /salary).

---

## 5. Scalability Considerations

| Concern | Strategy |
|---------|----------|
| 100→1000 employees | Pagination, indexed queries, date-range partitioning |
| Multi-warehouse | Add `warehouse_id` FK (nullable now, enforced later) |
| Multi-tenant | Backend already has tenant isolation via auth |
| Report generation | Background job for large exports; small reports inline |
| Concurrent attendance marking | Unique constraint on (employee_id, date) prevents duplicates |
| Payment integrity | DB transactions with row-level locks on salary settlement |

---

## 6. Security

- All endpoints behind JWT authentication
- Role-based: only `admin` role can access EMS (future: `manager` role with limited access)
- Aadhaar numbers encrypted at rest
- Photo URLs are presigned (expire after 1 hour)
- Salary data never exposed to non-admin roles

---

## 7. Technology Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter 3.x + Riverpod + GoRouter + Dio |
| Backend | Node.js + Express |
| Database | PostgreSQL |
| Storage | AWS S3 (employee photos) |
| Hosting | AWS ECS (existing infrastructure) |
| Auth | JWT Bearer tokens (existing) |
