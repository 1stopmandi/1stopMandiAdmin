import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/orders/presentation/screens/orders_list_screen.dart';
import '../../features/orders/presentation/screens/order_detail_screen.dart';
import '../../features/clients/presentation/screens/clients_list_screen.dart';
import '../../features/clients/presentation/screens/client_detail_screen.dart';
import '../../features/clients/presentation/screens/client_form_screen.dart';
import '../../features/products/presentation/screens/products_list_screen.dart';
import '../../features/products/presentation/screens/product_detail_screen.dart';
import '../../features/products/presentation/screens/product_form_screen.dart';
import '../../features/categories/presentation/screens/categories_list_screen.dart';
import '../../features/categories/presentation/screens/category_detail_screen.dart';
import '../../features/categories/presentation/screens/category_form_screen.dart';
import '../../features/uploaded_orders/presentation/screens/uploaded_orders_list_screen.dart';
import '../../features/uploaded_orders/presentation/screens/uploaded_order_detail_screen.dart';
import '../../features/users/presentation/screens/users_list_screen.dart';
import '../../features/users/presentation/screens/user_detail_screen.dart';
import '../../features/pricing/presentation/screens/legacy_pricing_list_screen.dart';
import '../../features/pricing/presentation/screens/legacy_pricing_edit_screen.dart';
import '../../features/pricing/presentation/screens/bulk_pricing_screen.dart';
import '../../features/employees/presentation/screens/employees_list_screen.dart';
import '../../features/employees/presentation/screens/employee_detail_screen.dart';
import '../../features/employees/presentation/screens/employee_form_screen.dart';
import '../../features/attendance/presentation/screens/attendance_mark_screen.dart';
import '../../features/attendance/presentation/screens/attendance_history_screen.dart';
import '../../features/salary/presentation/screens/salary_list_screen.dart';
import '../../features/salary/presentation/screens/salary_generate_screen.dart';
import '../../features/salary/presentation/screens/salary_detail_screen.dart';
import '../../features/employee_dashboard/presentation/screens/employee_dashboard_screen.dart';
import '../../features/inventory/presentation/screens/inventory_home_screen.dart';
import '../../features/inventory/presentation/screens/inventory_detail_screen.dart';
import '../../features/inventory/presentation/screens/inventory_form_screen.dart';
import '../../features/inventory_dashboard/presentation/screens/inventory_dashboard_screen.dart';
import '../../features/inventory_reports/presentation/screens/inventory_reports_home_screen.dart';
import '../../features/inventory_reports/presentation/screens/inventory_report_view_screen.dart';
import '../widgets/admin_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/orders',
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final isLoading = authState.isLoading;
      final isLoginRoute = state.matchedLocation == '/login';

      if (isLoading) return null;
      if (!isLoggedIn && !isLoginRoute) return '/login';
      if (isLoggedIn && isLoginRoute) return '/orders';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (_, __, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: '/orders',
            builder: (_, __) => const OrdersListScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, state) =>
                    OrderDetailScreen(orderId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: '/clients',
            builder: (_, __) => const ClientsListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (_, __) => const ClientFormScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (_, state) =>
                    ClientDetailScreen(clientId: state.pathParameters['id']!),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (_, state) => ClientFormScreen(
                      clientId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/products',
            builder: (_, __) => const ProductsListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (_, __) => const ProductFormScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (_, state) =>
                    ProductDetailScreen(productId: state.pathParameters['id']!),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (_, state) => ProductFormScreen(
                      productId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/categories',
            builder: (_, __) => const CategoriesListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (_, __) => const CategoryFormScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (_, state) => CategoryDetailScreen(
                  categoryId: state.pathParameters['id']!,
                ),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (_, state) => CategoryFormScreen(
                      categoryId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/uploaded-orders',
            builder: (_, __) => const UploadedOrdersListScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, state) => UploadedOrderDetailScreen(
                  uploadId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/users',
            builder: (_, __) => const UsersListScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, state) =>
                    UserDetailScreen(userId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: '/pricing/legacy',
            builder: (_, __) => const LegacyPricingListScreen(),
            routes: [
              GoRoute(
                path: ':productId',
                builder: (_, state) => LegacyPricingEditScreen(
                  productId: state.pathParameters['productId']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/pricing/bulk',
            builder: (_, __) => const BulkPricingScreen(),
          ),
          GoRoute(
            path: '/employees',
            builder: (_, __) => const EmployeesListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (_, __) => const EmployeeFormScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (_, state) =>
                    EmployeeDetailScreen(employeeId: state.pathParameters['id']!),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (_, state) => EmployeeFormScreen(
                      employeeId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/attendance',
            builder: (_, __) => const AttendanceMarkScreen(),
            routes: [
              GoRoute(
                path: 'history/:employeeId',
                builder: (_, state) => AttendanceHistoryScreen(
                  employeeId: state.pathParameters['employeeId']!,
                  employeeName: state.uri.queryParameters['name'] ?? 'Employee',
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/salary',
            builder: (_, __) => const SalaryListScreen(),
            routes: [
              GoRoute(
                path: 'generate',
                builder: (_, __) => const SalaryGenerateScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (_, state) =>
                    SalaryDetailScreen(periodId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: '/employee-dashboard',
            builder: (_, __) => const EmployeeDashboardScreen(),
          ),
          GoRoute(
            path: '/inventory-mgmt',
            builder: (_, __) => const InventoryHomeScreen(),
            routes: [
              GoRoute(
                path: 'create',
                builder: (_, __) => const InventoryFormScreen(),
              ),
              GoRoute(
                path: 'dashboard',
                builder: (_, __) => const InventoryDashboardScreen(),
              ),
              GoRoute(
                path: 'reports',
                builder: (_, __) => const InventoryReportsHomeScreen(),
                routes: [
                  GoRoute(
                    path: ':type',
                    builder: (_, state) => InventoryReportViewScreen(
                      reportType: state.pathParameters['type']!,
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: ':id',
                builder: (_, state) =>
                    InventoryDetailScreen(recordId: state.pathParameters['id']!),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (_, state) => InventoryFormScreen(
                      recordId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
