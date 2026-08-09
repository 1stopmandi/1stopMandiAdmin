import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final GlobalKey<ScaffoldState> adminShellScaffoldKey = GlobalKey<ScaffoldState>();

/// Bottom navigation + drawer for all admin sections.
class AdminShell extends StatelessWidget {
  final Widget child;

  const AdminShell({super.key, required this.child});

  int _selectedIndex(String location) {
    if (location.startsWith('/categories')) return 3;
    if (location.startsWith('/products')) return 2;
    if (location.startsWith('/clients')) return 1;
    return 0;
  }

  bool _isDrawerRoute(String location) {
    return location.startsWith('/uploaded-orders') ||
        location.startsWith('/users') ||
        location.startsWith('/pricing') ||
        location.startsWith('/employees') ||
        location.startsWith('/attendance') ||
        location.startsWith('/salary') ||
        location.startsWith('/employee-dashboard') ||
        location.startsWith('/inventory-mgmt');
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final index = _isDrawerRoute(location) ? 0 : _selectedIndex(location);

    return Scaffold(
      key: adminShellScaffoldKey,
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.green[800]),
              child: const Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  '1StopMandi Admin',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            _DrawerTile(
              icon: Icons.receipt_long,
              label: 'Orders',
              selected: location.startsWith('/orders'),
              onTap: () => _go(context, '/orders'),
            ),
            _DrawerTile(
              icon: Icons.storefront,
              label: 'Clients',
              selected: location.startsWith('/clients'),
              onTap: () => _go(context, '/clients'),
            ),
            _DrawerTile(
              icon: Icons.inventory_2,
              label: 'Products',
              selected: location.startsWith('/products'),
              onTap: () => _go(context, '/products'),
            ),
            _DrawerTile(
              icon: Icons.category,
              label: 'Categories',
              selected: location.startsWith('/categories'),
              onTap: () => _go(context, '/categories'),
            ),
            const Divider(),
            _DrawerTile(
              icon: Icons.upload_file,
              label: 'Uploaded Orders',
              selected: location.startsWith('/uploaded-orders'),
              onTap: () => _go(context, '/uploaded-orders'),
            ),
            _DrawerTile(
              icon: Icons.people,
              label: 'Users',
              selected: location.startsWith('/users'),
              onTap: () => _go(context, '/users'),
            ),
            _DrawerTile(
              icon: Icons.price_change,
              label: 'Legacy Pricing',
              selected: location.startsWith('/pricing/legacy'),
              onTap: () => _go(context, '/pricing/legacy'),
            ),
            _DrawerTile(
              icon: Icons.table_chart,
              label: 'Bulk Pricing',
              selected: location == '/pricing/bulk',
              onTap: () => _go(context, '/pricing/bulk'),
            ),
            const Divider(),
            _DrawerTile(
              icon: Icons.badge,
              label: 'Employees',
              selected: location.startsWith('/employees'),
              onTap: () => _go(context, '/employees'),
            ),
            _DrawerTile(
              icon: Icons.fact_check,
              label: 'Attendance',
              selected: location.startsWith('/attendance'),
              onTap: () => _go(context, '/attendance'),
            ),
            _DrawerTile(
              icon: Icons.account_balance_wallet,
              label: 'Salary',
              selected: location.startsWith('/salary'),
              onTap: () => _go(context, '/salary'),
            ),
            _DrawerTile(
              icon: Icons.dashboard,
              label: 'EMS Dashboard',
              selected: location.startsWith('/employee-dashboard'),
              onTap: () => _go(context, '/employee-dashboard'),
            ),
            const Divider(),
            _DrawerTile(
              icon: Icons.book,
              label: 'Inventory',
              selected: location == '/inventory-mgmt' || (location.startsWith('/inventory-mgmt') && !location.contains('dashboard')),
              onTap: () => _go(context, '/inventory-mgmt'),
            ),
            _DrawerTile(
              icon: Icons.analytics,
              label: 'Inventory Dashboard',
              selected: location.startsWith('/inventory-mgmt/dashboard'),
              onTap: () => _go(context, '/inventory-mgmt/dashboard'),
            ),
            _DrawerTile(
              icon: Icons.assessment,
              label: 'Inventory Reports',
              selected: location.startsWith('/inventory-mgmt/reports'),
              onTap: () => _go(context, '/inventory-mgmt/reports'),
            ),
          ],
        ),
      ),
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) {
          switch (i) {
            case 0:
              context.go('/orders');
            case 1:
              context.go('/clients');
            case 2:
              context.go('/products');
            case 3:
              context.go('/categories');
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: 'Clients',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Products',
          ),
          NavigationDestination(
            icon: Icon(Icons.category_outlined),
            selectedIcon: Icon(Icons.category),
            label: 'Categories',
          ),
        ],
      ),
    );
  }

  void _go(BuildContext context, String path) {
    Navigator.pop(context);
    context.go(path);
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: selected ? Colors.green[800] : null),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          color: selected ? Colors.green[800] : null,
        ),
      ),
      selected: selected,
      onTap: onTap,
    );
  }
}
