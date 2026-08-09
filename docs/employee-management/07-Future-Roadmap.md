# Future Roadmap — Employee Management System

## Phase 1: Foundation (Current Sprint)

### Scope
Build the core EMS with minimum viable features for immediate business use.

### Deliverables
| Module | Features |
|--------|----------|
| Employee CRUD | Add, edit, soft-delete, search, filter, status management |
| Daily Attendance | Mark attendance (single + bulk), edit past attendance, working hours |
| Salary Calculation | Auto-compute from attendance, generate for date range |
| Salary Settlement | Full/partial payment, payment history, cash/UPI/bank |
| Employee Exit | Mark as left, final settlement |
| Dashboard | Basic metrics (total, present, absent, pending salary) |
| Reports | Daily attendance report, monthly salary report (PDF only) |

### Constraints
- Single warehouse (no multi-location)
- No shifts
- No advances/loans
- No leave management system
- Monthly salary type only (daily_wage derived)
- Admin-only access (no manager role)
- No mobile app for employees (admin-only marking)

---

## Phase 2: Enhanced Operations (Month 2-3)

### 2.1 Shift Management
- Define multiple shifts (Morning 6AM-2PM, Day 9AM-6PM, Night 10PM-6AM)
- Assign employees to shifts
- Attendance auto-validates against shift timing
- Overtime calculation: hours beyond shift duration

### 2.2 Leave Management
- Define leave types: Casual Leave, Sick Leave, Earned Leave
- Leave balance per employee per year
- Leave application workflow (future: employee self-service)
- Configurable: paid leave vs unpaid leave
- Leave impacts salary calculation (paid leave = 1 payable day)

### 2.3 Advance / Loan System
- Admin can give salary advances to employees
- Deduction from future salary (configurable installments)
- Track: advance amount, date, remaining balance
- Auto-deduct from salary settlement
- Interest-free (current business practice)

### 2.4 Overtime & Bonus
- Overtime hours: beyond standard shift (configurable per shift)
- Overtime rate: 1.5× or 2× daily wage per hour
- Festival bonus: one-time payments
- Performance bonus: discretionary

### 2.5 Export Enhancements
- Excel export for all reports
- CSV export for data processing
- Automated monthly report generation
- Email reports to admin

---

## Phase 3: Scale & Automation (Month 4-6)

### 3.1 Multi-Warehouse Support
- `warehouse_id` on employees and attendance
- Warehouse-specific dashboards
- Inter-warehouse transfers (employee moves)
- Warehouse manager role with limited access

### 3.2 Role-Based Access Control
| Role | Permissions |
|------|------------|
| Super Admin | Everything + system config + audit access |
| Admin | All EMS operations |
| Manager | Mark attendance, view salary (own warehouse) |
| Accountant | Salary settlement, payments, reports |
| Viewer | Read-only access to reports |

### 3.3 Employee Self-Service (Mobile)
- Employees get a simple app/web view
- View own attendance
- View salary slips
- Apply for leave
- Update personal info

### 3.4 Biometric / QR Attendance
- QR code scanning for check-in/check-out
- Geo-fencing: must be within warehouse radius
- Auto-generates attendance from scan logs
- Replaces manual admin marking for day-to-day

### 3.5 Notifications
- Push notifications to admin: unmarked attendance at EOD
- Salary due reminders
- Employee birthday/anniversary alerts
- Leave approval notifications

### 3.6 Analytics & Insights
- Attendance trends (which days have most absenteeism?)
- Employee retention rate
- Cost per designation analysis
- Seasonal workforce planning

---

## Phase 4: Compliance & Integration (Month 7+)

### 4.1 Statutory Compliance
- PF (Provident Fund) calculation
- ESI (Employee State Insurance)
- Professional Tax deduction
- TDS for applicable salary slabs
- Compliance reports for government filings

### 4.2 Contract Workers
- Fixed-term contracts with start/end dates
- Auto-deactivate on contract expiry
- Contract renewal workflow
- Different salary structures per contract type

### 4.3 Integration with Accounting
- Export salary data to Tally/accounting software
- Bank file generation for bulk salary transfers (NEFT/RTGS)
- Reconciliation reports

### 4.4 Document Management
- Store employee documents (ID proofs, contracts, offer letters)
- Document expiry alerts (if applicable)
- Digital salary slips / pay stubs

### 4.5 Performance Tracking (Basic)
- Daily task assignment (optional)
- Productivity metrics: units packed, loads completed
- Performance-based incentive calculation

---

## Schema Evolution Plan

### Phase 1 (Current)
```sql
-- Tables: employees, attendance, salary_periods, salary_payments, shifts (empty), audit_logs
-- Nullable columns ready for Phase 2: shift_id on attendance
```

### Phase 2 Additions
```sql
-- New tables:
CREATE TABLE leave_types (...);
CREATE TABLE leave_balances (...);
CREATE TABLE leave_requests (...);
CREATE TABLE advances (...);
CREATE TABLE advance_deductions (...);

-- New columns:
ALTER TABLE attendance ADD COLUMN overtime_hours DECIMAL(4,2);
ALTER TABLE salary_periods ADD COLUMN overtime_pay DECIMAL(10,2);
ALTER TABLE salary_periods ADD COLUMN bonus DECIMAL(10,2);
ALTER TABLE salary_periods ADD COLUMN advance_deduction DECIMAL(10,2);
```

### Phase 3 Additions
```sql
-- New tables:
CREATE TABLE warehouses (...);
CREATE TABLE roles (...);
CREATE TABLE permissions (...);
CREATE TABLE role_permissions (...);
CREATE TABLE user_roles (...);
CREATE TABLE qr_scan_logs (...);
CREATE TABLE notifications (...);

-- New columns:
ALTER TABLE employees ADD COLUMN warehouse_id UUID REFERENCES warehouses(id);
ALTER TABLE attendance ADD COLUMN source ENUM('manual', 'qr_scan', 'biometric');
```

### Phase 4 Additions
```sql
-- New tables:
CREATE TABLE statutory_config (...);
CREATE TABLE pf_contributions (...);
CREATE TABLE esi_contributions (...);
CREATE TABLE contracts (...);
CREATE TABLE documents (...);
CREATE TABLE tasks (...);
CREATE TABLE task_completions (...);
```

---

## Migration Strategy (Between Phases)

1. All new columns are **nullable** or have **defaults** — zero downtime migrations
2. New tables are additive — never modify existing table structure destructively
3. Enums extended via `ALTER TYPE ... ADD VALUE` (PostgreSQL supports this)
4. Data migrations run as separate scripts after schema migration
5. Feature flags control UI visibility until backend is ready
6. Old API versions remain functional for 2 releases

---

## Decision Log

| Decision | Rationale | Revisit When |
|----------|-----------|--------------|
| Monthly salary stored, daily computed | Business hires at monthly rate; daily varies by month length | Never — this is the business model |
| No shifts in Phase 1 | Current ops has no shifts; shift_id column placeholder ready | When warehouse runs >1 shift |
| Pull-based salary calc (not event-driven) | Simpler; recalc on GET/generate; < 100 employees | Employee count > 500 |
| Single warehouse assumed | Only 1 warehouse currently | When 2nd warehouse opens |
| Admin-only marking | No employee devices yet | When QR/biometric hardware procured |
| PDF-only export Phase 1 | Quickest to implement; covers main use case | When accountant asks for Excel |
| No PF/ESI in Phase 1 | Employees are daily-wage; may not qualify | When monthly employees added |
