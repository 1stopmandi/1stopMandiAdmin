# Folder Structure — Employee Management System

## 1. Flutter Frontend (Admin Panel)

```
lib/
├── core/                              # Shared infrastructure
│   ├── config/
│   │   └── env.dart                   # API base URL config
│   ├── network/
│   │   ├── api_client.dart            # Dio singleton
│   │   └── api_exceptions.dart        # Error types
│   ├── providers/
│   │   └── providers.dart             # Global Riverpod providers
│   ├── router/
│   │   └── app_router.dart            # GoRouter config
│   ├── utils/
│   │   ├── date_utils.dart            # Date formatting helpers
│   │   ├── currency_utils.dart        # ₹ formatting
│   │   └── media_url.dart             # S3 URL helpers
│   └── widgets/
│       ├── admin_shell.dart           # App shell / scaffold
│       ├── admin_menu_button.dart     # Navigation menu
│       ├── loading_indicator.dart     # Shared loading widget
│       ├── error_view.dart            # Shared error widget
│       └── confirmation_dialog.dart   # Reusable confirmation
│
├── data/                              # Data layer (shared models)
│   ├── local/
│   │   └── token_storage.dart         # Secure token storage
│   ├── models/                        # Existing models...
│   │   ├── user.dart
│   │   ├── order.dart
│   │   └── ...
│   └── repositories/                  # Existing repos...
│       ├── auth_repository.dart
│       └── ...
│
├── features/                          # Feature modules
│   ├── auth/                          # Existing
│   ├── orders/                        # Existing
│   ├── ...                            # Other existing features
│   │
│   ├── employees/                     # ──── NEW: Employee Module ────
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   └── employee.dart              # Employee model
│   │   │   └── repositories/
│   │   │       └── employee_repository.dart   # API calls
│   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   │   ├── employees_list_screen.dart     # List + search + filter
│   │   │   │   ├── employee_detail_screen.dart    # View profile
│   │   │   │   └── employee_form_screen.dart      # Add / Edit form
│   │   │   └── widgets/
│   │   │       ├── employee_card.dart             # List item card
│   │   │       ├── employee_status_badge.dart     # Status chip
│   │   │       ├── employee_filter_bar.dart       # Filter controls
│   │   │       └── employee_search_bar.dart       # Search input
│   │   └── providers/
│   │       └── employees_provider.dart            # Riverpod state
│   │
│   ├── attendance/                    # ──── NEW: Attendance Module ────
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   └── attendance.dart            # Attendance model
│   │   │   └── repositories/
│   │   │       └── attendance_repository.dart # API calls
│   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   │   ├── attendance_mark_screen.dart    # Daily marking
│   │   │   │   ├── attendance_history_screen.dart # Employee history
│   │   │   │   └── attendance_report_screen.dart  # Monthly view
│   │   │   └── widgets/
│   │   │       ├── attendance_row.dart            # Single employee row
│   │   │       ├── attendance_status_selector.dart # Status dropdown
│   │   │       ├── time_picker_field.dart         # Check-in/out input
│   │   │       ├── attendance_summary_card.dart   # Daily summary
│   │   │       └── attendance_calendar.dart       # Monthly calendar view
│   │   └── providers/
│   │       └── attendance_provider.dart           # Riverpod state
│   │
│   ├── salary/                        # ──── NEW: Salary Module ────
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   ├── salary_period.dart         # Salary period model
│   │   │   │   └── salary_payment.dart        # Payment model
│   │   │   └── repositories/
│   │   │       └── salary_repository.dart     # API calls
│   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   │   ├── salary_generate_screen.dart    # Generate salary
│   │   │   │   ├── salary_settlement_screen.dart  # Settlement/payment
│   │   │   │   ├── salary_detail_screen.dart      # Period detail
│   │   │   │   └── salary_history_screen.dart     # Payment history
│   │   │   └── widgets/
│   │   │       ├── salary_breakdown_card.dart     # Single employee breakdown
│   │   │       ├── salary_summary_table.dart      # Table of all employees
│   │   │       ├── payment_form.dart              # Payment entry form
│   │   │       └── payment_method_selector.dart   # Cash/UPI/Bank
│   │   └── providers/
│   │       └── salary_provider.dart               # Riverpod state
│   │
│   ├── reports/                       # ──── NEW: Reports Module ────
│   │   ├── data/
│   │   │   └── repositories/
│   │   │       └── reports_repository.dart    # Report API calls
│   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   │   ├── reports_home_screen.dart       # Report selection
│   │   │   │   ├── attendance_report_view.dart    # Attendance report
│   │   │   │   ├── salary_report_view.dart        # Salary report
│   │   │   │   └── employee_report_view.dart      # Employee history
│   │   │   └── widgets/
│   │   │       ├── report_filter_bar.dart         # Date range selector
│   │   │       ├── export_button.dart             # PDF/Excel/CSV
│   │   │       └── report_table.dart              # Generic data table
│   │   └── providers/
│   │       └── reports_provider.dart              # Riverpod state
│   │
│   └── employee_dashboard/            # ──── NEW: Dashboard Module ────
│       ├── data/
│       │   └── repositories/
│       │       └── dashboard_repository.dart  # Dashboard API calls
│       ├── presentation/
│       │   ├── screens/
│       │   │   └── employee_dashboard_screen.dart # Main dashboard
│       │   └── widgets/
│       │       ├── stat_card.dart                  # Metric card
│       │       ├── attendance_pie_chart.dart       # Today's breakdown
│       │       ├── salary_progress_bar.dart        # Paid vs pending
│       │       └── quick_actions_row.dart          # Mark attendance, etc.
│       └── providers/
│           └── dashboard_provider.dart            # Riverpod state
│
├── services/
│   └── fcm_service.dart               # Firebase messaging
├── app.dart                           # App widget
└── main.dart                          # Entry point
```

---

## 2. Backend (Node.js / Express)

```
src/
├── config/
│   ├── database.js                    # PostgreSQL connection pool
│   ├── env.js                         # Environment variables
│   └── s3.js                          # AWS S3 client config
│
├── middleware/
│   ├── auth.js                        # JWT verification
│   ├── role.js                        # Role-based access control
│   ├── validate.js                    # Request validation wrapper
│   └── error-handler.js              # Global error handler
│
├── modules/
│   ├── auth/                          # Existing auth module
│   │
│   ├── employees/                     # ──── Employee Module ────
│   │   ├── employee.controller.js     # Route handlers
│   │   ├── employee.service.js        # Business logic
│   │   ├── employee.repository.js     # Database queries
│   │   ├── employee.routes.js         # Express routes
│   │   ├── employee.validator.js      # Joi/Zod schemas
│   │   └── employee.dto.js            # Response transformations
│   │
│   ├── attendance/                    # ──── Attendance Module ────
│   │   ├── attendance.controller.js
│   │   ├── attendance.service.js
│   │   ├── attendance.repository.js
│   │   ├── attendance.routes.js
│   │   ├── attendance.validator.js
│   │   └── attendance.dto.js
│   │
│   ├── salary/                        # ──── Salary Module ────
│   │   ├── salary.controller.js
│   │   ├── salary.service.js          # Salary calculation logic
│   │   ├── salary.repository.js
│   │   ├── salary.routes.js
│   │   ├── salary.validator.js
│   │   └── salary.dto.js
│   │
│   ├── payments/                      # ──── Payments Module ────
│   │   ├── payment.controller.js
│   │   ├── payment.service.js
│   │   ├── payment.repository.js
│   │   ├── payment.routes.js
│   │   ├── payment.validator.js
│   │   └── payment.dto.js
│   │
│   ├── reports/                       # ──── Reports Module ────
│   │   ├── report.controller.js
│   │   ├── report.service.js
│   │   ├── report.repository.js
│   │   ├── report.routes.js
│   │   └── report.generators/
│   │       ├── pdf-generator.js       # PDF export via puppeteer/pdfkit
│   │       ├── excel-generator.js     # Excel via exceljs
│   │       └── csv-generator.js       # CSV export
│   │
│   └── dashboard/                     # ──── Dashboard Module ────
│       ├── dashboard.controller.js
│       ├── dashboard.service.js
│       ├── dashboard.repository.js
│       └── dashboard.routes.js
│
├── shared/
│   ├── audit-logger.js                # Audit log helper
│   ├── pagination.js                  # Pagination helper
│   ├── errors.js                      # Custom error classes
│   └── constants.js                   # Enums and constants
│
├── database/
│   ├── migrations/                    # SQL migration files
│   │   ├── 001_create_employee_enums.sql
│   │   ├── 002_create_employees_table.sql
│   │   ├── 003_create_shifts_table.sql
│   │   ├── 004_create_attendance_table.sql
│   │   ├── 005_create_salary_periods_table.sql
│   │   ├── 006_create_salary_payments_table.sql
│   │   ├── 007_create_audit_logs_table.sql
│   │   └── 008_create_indexes.sql
│   └── seeds/
│       └── seed_employees.js          # Development seed data
│
├── routes/
│   └── index.js                       # Route aggregator
│
├── app.js                             # Express app setup
└── server.js                          # Server entry point
```

---

## 3. Module Dependency Graph

```
employee_dashboard ─────┐
                        │
reports ────────────────┼──> salary ──────> attendance ──────> employees
                        │       │                                  │
payments ───────────────┘       └──────────────────────────────────┘
```

- **employees** is the foundational module (no dependencies)
- **attendance** depends on employees (FK relationship)
- **salary** depends on attendance + employees (calculation)
- **payments** depends on salary (settlement)
- **reports** depends on all above (aggregation)
- **dashboard** depends on all above (metrics)

---

## 4. Naming Conventions

| Layer | Convention | Example |
|-------|-----------|---------|
| Models (Flutter) | PascalCase, singular | `Employee`, `AttendanceRecord` |
| Repositories (Flutter) | PascalCase, singular + Repository | `EmployeeRepository` |
| Providers (Flutter) | camelCase + Provider suffix | `employeesProvider`, `attendanceProvider` |
| Screens (Flutter) | PascalCase + Screen | `EmployeesListScreen` |
| Controllers (Backend) | camelCase functions | `getEmployees`, `createEmployee` |
| Services (Backend) | camelCase functions | `calculateSalary`, `markAttendance` |
| DB Tables | snake_case, plural | `employees`, `salary_periods` |
| DB Columns | snake_case | `employee_id`, `monthly_salary` |
| API Routes | kebab-case, plural | `/api/employees`, `/api/salary-periods` |
| Files (Backend) | kebab-case or dot notation | `employee.service.js` |
| Files (Flutter) | snake_case | `employee_repository.dart` |
