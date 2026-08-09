# API Design — Employee Management System

## Base URL
```
/api/employees      — Employee CRUD
/api/attendance     — Attendance management
/api/salary         — Salary periods & calculations
/api/payments       — Salary payments/settlements
/api/reports        — Report generation
/api/dashboard      — Dashboard metrics
```

All endpoints require `Authorization: Bearer <token>` header.  
All responses follow the shape: `{ success: true, data: {...} }` or `{ success: false, message: "..." }`.

---

## 1. Employee Management APIs

### 1.1 List Employees
```
GET /api/employees
```

**Query Parameters:**
| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `page` | number | 1 | Page number |
| `limit` | number | 20 | Items per page |
| `status` | string | all | Filter: active, inactive, left |
| `designation` | string | all | Filter by designation |
| `search` | string | — | Search by name or mobile |
| `sort_by` | string | created_at | Sort field |
| `sort_order` | string | desc | asc or desc |

**Response:**
```json
{
  "success": true,
  "data": {
    "employees": [
      {
        "id": "uuid",
        "employee_code": "EMP-001",
        "full_name": "Raju Kumar",
        "mobile_number": "9876543210",
        "designation": "loader",
        "status": "active",
        "monthly_salary": 21000,
        "joining_date": "2025-03-15"
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 45,
      "total_pages": 3
    }
  }
}
```

---

### 1.2 Get Employee Detail
```
GET /api/employees/:id
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "employee_code": "EMP-001",
    "full_name": "Raju Kumar",
    "mobile_number": "9876543210",
    "alternate_number": null,
    "address": "Near Sabzi Mandi, Patna",
    "aadhaar_number": "XXXX-XXXX-1234",
    "photo_url": "https://s3.../employee-photos/uuid.jpg?presigned...",
    "emergency_contact": "9876543211",
    "joining_date": "2025-03-15",
    "status": "active",
    "employee_type": "daily_wage",
    "designation": "loader",
    "monthly_salary": 21000,
    "notes": null,
    "created_at": "2025-03-15T10:00:00Z",
    "updated_at": "2025-03-15T10:00:00Z"
  }
}
```

---

### 1.3 Create Employee
```
POST /api/employees
```

**Request Body:**
```json
{
  "full_name": "Raju Kumar",
  "mobile_number": "9876543210",
  "alternate_number": null,
  "address": "Near Sabzi Mandi, Patna",
  "aadhaar_number": "123456789012",
  "emergency_contact": "9876543211",
  "joining_date": "2025-03-15",
  "employee_type": "daily_wage",
  "designation": "loader",
  "monthly_salary": 21000,
  "notes": "Referred by Suresh"
}
```

**Validation Rules:**
| Field | Rules |
|-------|-------|
| `full_name` | Required, 2-100 chars |
| `mobile_number` | Required, 10 digits, unique among active employees |
| `alternate_number` | Optional, 10 digits |
| `address` | Required, min 10 chars |
| `aadhaar_number` | Optional, exactly 12 digits |
| `emergency_contact` | Required, 10 digits |
| `joining_date` | Required, valid date, not future |
| `employee_type` | Required, one of: daily_wage, monthly, contract |
| `designation` | Required, one of: packing_staff, loader, helper, cleaner, warehouse_staff, other |
| `monthly_salary` | Required, positive number, max 200000 |

**Response:** `201 Created`
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "employee_code": "EMP-046",
    "full_name": "Raju Kumar",
    "...": "..."
  }
}
```

---

### 1.4 Update Employee
```
PUT /api/employees/:id
```

**Request Body:** Same as create (partial updates allowed — send only changed fields).

**Response:** `200 OK` with updated employee.

---

### 1.5 Delete Employee (Soft)
```
DELETE /api/employees/:id
```

Sets `deleted_at = NOW()`. Employee won't appear in list queries.

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Employee soft-deleted successfully"
}
```

---

### 1.6 Update Employee Status
```
PATCH /api/employees/:id/status
```

**Request Body:**
```json
{
  "status": "left",
  "notes": "Employee resigned on 2025-07-20"
}
```

**Business Rules:**
- `active` → `inactive`: Allowed anytime
- `active` → `left`: Check for pending salary, warn if exists
- `inactive` → `active`: Re-activation
- `left` → any: Not allowed (final state)

**Response:** `200 OK`

---

### 1.7 Upload Employee Photo
```
POST /api/employees/:id/photo
Content-Type: multipart/form-data
```

**Body:** `photo` field with image file (JPEG/PNG, max 5MB)

**Response:**
```json
{
  "success": true,
  "data": {
    "photo_url": "https://s3.../employee-photos/uuid.jpg"
  }
}
```

---

## 2. Attendance APIs

### 2.1 Mark Attendance (Single)
```
POST /api/attendance
```

**Request Body:**
```json
{
  "employee_id": "uuid",
  "date": "2025-07-20",
  "status": "present",
  "check_in_time": "09:00",
  "check_out_time": "18:00",
  "notes": null
}
```

**Validation Rules:**
| Field | Rules |
|-------|-------|
| `employee_id` | Required, must exist, must be active |
| `date` | Required, not future, not older than 7 days |
| `status` | Required, one of: present, half_day, absent, leave, holiday |
| `check_in_time` | Optional, HH:mm format |
| `check_out_time` | Optional, HH:mm, must be after check_in_time |

**Response:** `201 Created`
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "employee_id": "uuid",
    "date": "2025-07-20",
    "status": "present",
    "check_in_time": "09:00",
    "check_out_time": "18:00",
    "total_working_hours": 9.0
  }
}
```

---

### 2.2 Mark Attendance (Bulk)
```
POST /api/attendance/bulk
```

**Request Body:**
```json
{
  "date": "2025-07-20",
  "records": [
    { "employee_id": "uuid-1", "status": "present", "check_in_time": "09:00", "check_out_time": "18:00" },
    { "employee_id": "uuid-2", "status": "absent" },
    { "employee_id": "uuid-3", "status": "half_day", "check_in_time": "09:00", "check_out_time": "13:00" }
  ]
}
```

**Response:** `200 OK` with array of created/updated records.

---

### 2.3 Update Attendance
```
PUT /api/attendance/:id
```

**Request Body:** Same as single mark (partial update).

**Business Rule:** Cannot update attendance if the salary period for that date is already `paid`.

---

### 2.4 Get Attendance for Date
```
GET /api/attendance?date=2025-07-20
```

Returns all employees with their attendance status for that date. Employees without a record are shown as "unmarked".

**Response:**
```json
{
  "success": true,
  "data": {
    "date": "2025-07-20",
    "summary": {
      "total_employees": 45,
      "present": 38,
      "half_day": 2,
      "absent": 3,
      "leave": 1,
      "holiday": 0,
      "unmarked": 1
    },
    "records": [
      {
        "id": "uuid",
        "employee_id": "uuid",
        "employee_name": "Raju Kumar",
        "employee_code": "EMP-001",
        "designation": "loader",
        "date": "2025-07-20",
        "status": "present",
        "check_in_time": "09:00",
        "check_out_time": "18:00",
        "total_working_hours": 9.0
      }
    ]
  }
}
```

---

### 2.5 Get Employee Attendance History
```
GET /api/attendance/employee/:employee_id?start_date=2025-07-01&end_date=2025-07-31
```

**Response:** Array of attendance records for that employee in the date range.

---

## 3. Salary APIs

### 3.1 Generate Salary (Preview)
```
POST /api/salary/generate
```

**Request Body:**
```json
{
  "employee_ids": ["uuid-1", "uuid-2"],
  "period_start": "2025-07-01",
  "period_end": "2025-07-15"
}
```

If `employee_ids` is empty or omitted, generates for ALL active employees.

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "period_start": "2025-07-01",
    "period_end": "2025-07-15",
    "salary_breakdown": [
      {
        "employee_id": "uuid-1",
        "employee_name": "Raju Kumar",
        "employee_code": "EMP-001",
        "monthly_salary": 21000,
        "days_in_month": 31,
        "daily_wage": 677.42,
        "present_days": 12,
        "half_days": 1,
        "absent_days": 2,
        "leave_days": 0,
        "holiday_days": 0,
        "payable_days": 12.5,
        "total_working_hours": 112.5,
        "gross_salary": 8467.74,
        "previous_pending": 0,
        "advances": 0,
        "final_payable": 8467.74
      }
    ]
  }
}
```

---

### 3.2 Confirm Salary Generation
```
POST /api/salary/confirm
```

**Request Body:**
```json
{
  "period_start": "2025-07-01",
  "period_end": "2025-07-15",
  "employee_ids": ["uuid-1", "uuid-2"]
}
```

Creates `salary_periods` records with status `generated`.

**Response:** `201 Created` with salary period IDs.

---

### 3.3 Get Salary Periods
```
GET /api/salary?employee_id=uuid&status=generated&period_start=2025-07-01
```

**Query Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `employee_id` | UUID | Filter by employee |
| `status` | string | generated, partial, paid, cancelled |
| `period_start` | date | Filter by start date |
| `period_end` | date | Filter by end date |

---

### 3.4 Get Salary Period Detail
```
GET /api/salary/:id
```

Returns salary period with all associated payments.

---

### 3.5 Recalculate Salary
```
POST /api/salary/:id/recalculate
```

Re-computes salary from current attendance data (only if status is `generated` or `partial`).

---

## 4. Payment APIs

### 4.1 Record Payment
```
POST /api/payments
```

**Request Body:**
```json
{
  "salary_period_id": "uuid",
  "amount_paid": 8467.74,
  "payment_method": "upi",
  "payment_date": "2025-07-16",
  "transaction_reference": "UPI-REF-123456",
  "notes": "Full payment for first half July"
}
```

**Validation Rules:**
| Field | Rules |
|-------|-------|
| `salary_period_id` | Required, must exist, must not be `paid` or `cancelled` |
| `amount_paid` | Required, positive, ≤ remaining balance |
| `payment_method` | Required, one of: cash, upi, bank_transfer |
| `payment_date` | Required, valid date |
| `transaction_reference` | Optional for cash, recommended for UPI/bank |

**Business Logic:**
- If total paid = final_payable → salary_period.status = `paid`
- If total paid < final_payable → salary_period.status = `partial`

**Response:** `201 Created`

---

### 4.2 Get Payments for Salary Period
```
GET /api/payments?salary_period_id=uuid
```

---

### 4.3 Get Payment History
```
GET /api/payments/history?employee_id=uuid&start_date=2025-01-01&end_date=2025-07-31
```

---

## 5. Report APIs

### 5.1 Daily Attendance Report
```
GET /api/reports/attendance/daily?date=2025-07-20
```

### 5.2 Monthly Attendance Report
```
GET /api/reports/attendance/monthly?month=2025-07
```

### 5.3 Salary Report
```
GET /api/reports/salary?period_start=2025-07-01&period_end=2025-07-31
```

### 5.4 Pending Salary Report
```
GET /api/reports/salary/pending
```

### 5.5 Employee History
```
GET /api/reports/employee/:id/history
```

### 5.6 Export Report
```
GET /api/reports/export?type=attendance_monthly&month=2025-07&format=pdf
```

**Query Parameters:**
| Param | Values |
|-------|--------|
| `type` | attendance_daily, attendance_monthly, salary, pending_salary, employee_history, payroll_summary |
| `format` | pdf, excel, csv |

**Response:** File download (Content-Disposition: attachment).

---

## 6. Dashboard API

### 6.1 Get Dashboard Metrics
```
GET /api/dashboard/employees
```

**Response:**
```json
{
  "success": true,
  "data": {
    "total_employees": 45,
    "active_employees": 42,
    "today_present": 38,
    "today_absent": 3,
    "today_half_day": 1,
    "today_unmarked": 0,
    "salary_pending_count": 5,
    "salary_pending_amount": 42000,
    "salary_paid_this_month": 380000,
    "attendance_percentage": 91.5,
    "month": "2025-07"
  }
}
```

---

## 7. Error Handling

### Standard Error Response
```json
{
  "success": false,
  "message": "Employee not found",
  "error_code": "EMPLOYEE_NOT_FOUND",
  "details": null
}
```

### Validation Error Response
```json
{
  "success": false,
  "message": "Validation failed",
  "error_code": "VALIDATION_ERROR",
  "details": [
    { "field": "mobile_number", "message": "Must be exactly 10 digits" },
    { "field": "monthly_salary", "message": "Must be a positive number" }
  ]
}
```

### Error Codes
| Code | HTTP Status | Description |
|------|-------------|-------------|
| `VALIDATION_ERROR` | 400 | Request body validation failed |
| `EMPLOYEE_NOT_FOUND` | 404 | Employee ID doesn't exist |
| `ATTENDANCE_EXISTS` | 409 | Attendance already marked for this date |
| `ATTENDANCE_LOCKED` | 403 | Cannot modify — salary already paid |
| `SALARY_ALREADY_PAID` | 400 | Salary period already fully paid |
| `SALARY_OVERLAP` | 409 | Overlapping salary period exists |
| `PAYMENT_EXCEEDS_BALANCE` | 400 | Payment amount > remaining balance |
| `EMPLOYEE_HAS_PENDING` | 400 | Cannot deactivate — pending salary exists |
| `UNAUTHORIZED` | 401 | Invalid or expired token |
| `FORBIDDEN` | 403 | Insufficient role permissions |
