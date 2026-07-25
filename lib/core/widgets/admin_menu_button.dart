import 'package:flutter/material.dart';
import 'admin_shell.dart';

/// Opens the admin shell drawer from nested screens.
class AdminMenuButton extends StatelessWidget {
  const AdminMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.menu),
      onPressed: () => adminShellScaffoldKey.currentState?.openDrawer(),
    );
  }
}
