import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/auth/session_service.dart';
import '../../blog/view/blog_list_page.dart';
import '../../dashboard/view/dashboard_page.dart';
import '../../home/view/home_page.dart';
import '../../orders/view/admin_orders_page.dart';
import '../../orders/view/client_orders_page.dart';
import '../../packages/view/packages_page.dart';
import '../../profile/view/account_page.dart';
import '../../tasks/view/admin_tasks_page.dart';
import '../../tasks/view/employee_tasks_page.dart';
import '../controller/shell_controllers.dart';

/// Bottom-navigation scaffold shared by the three role shells. Tabs are kept
/// alive in an IndexedStack so switching doesn't reload them.
class _Shell extends StatelessWidget {
  const _Shell({
    required this.controller,
    required this.pages,
    required this.destinations,
  });

  final ShellController controller;
  final List<Widget> pages;
  final List<NavigationDestination> destinations;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        body: IndexedStack(index: controller.index.value, children: pages),
        bottomNavigationBar: NavigationBar(
          selectedIndex: controller.index.value,
          onDestinationSelected: controller.select,
          destinations: destinations,
        ),
      ),
    );
  }
}

class ClientShellPage extends GetView<ClientShellController> {
  const ClientShellPage({super.key});

  @override
  Widget build(BuildContext context) => Obx(() {
    final signedIn = SessionService.to.isSignedIn;
    return _Shell(
      controller: controller,
      pages: [
        const HomePage(),
        const PackagesPage(),
        signedIn
            ? const ClientOrdersPage()
            : const _SignInPrompt(message: 'Sign in to see your projects.'),
        const BlogListPage(),
        signedIn
            ? const AccountPage()
            : const _SignInPrompt(message: 'Sign in to view your account.'),
      ],
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.grid_view_outlined),
          selectedIcon: Icon(Icons.grid_view_rounded),
          label: 'Packages',
        ),
        NavigationDestination(
          icon: Icon(Icons.work_outline),
          selectedIcon: Icon(Icons.work),
          label: 'Projects',
        ),
        NavigationDestination(
          icon: Icon(Icons.article_outlined),
          selectedIcon: Icon(Icons.article),
          label: 'Blog',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Account',
        ),
      ],
    );
  });
}

class _SignInPrompt extends StatelessWidget {
  const _SignInPrompt({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.lock_outline,
              size: 40,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Get.toNamed(AppRoutes.login),
              child: const Text('Sign in'),
            ),
          ],
        ),
      ),
    ),
  );
}

class EmployeeShellPage extends GetView<EmployeeShellController> {
  const EmployeeShellPage({super.key});

  @override
  Widget build(BuildContext context) => _Shell(
    controller: controller,
    pages: const [EmployeeTasksPage(), AccountPage()],
    destinations: const [
      NavigationDestination(
        icon: Icon(Icons.task_alt_outlined),
        selectedIcon: Icon(Icons.task_alt),
        label: 'Tasks',
      ),
      NavigationDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person),
        label: 'Account',
      ),
    ],
  );
}

class AdminShellPage extends GetView<AdminShellController> {
  const AdminShellPage({super.key});

  @override
  Widget build(BuildContext context) => _Shell(
    controller: controller,
    pages: const [
      DashboardPage(),
      AdminOrdersPage(),
      AdminTasksPage(),
      AccountPage(),
    ],
    destinations: const [
      NavigationDestination(
        icon: Icon(Icons.insights_outlined),
        selectedIcon: Icon(Icons.insights),
        label: 'Dashboard',
      ),
      NavigationDestination(
        icon: Icon(Icons.receipt_long_outlined),
        selectedIcon: Icon(Icons.receipt_long),
        label: 'Orders',
      ),
      NavigationDestination(
        icon: Icon(Icons.task_outlined),
        selectedIcon: Icon(Icons.task),
        label: 'Tasks',
      ),
      NavigationDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person),
        label: 'Account',
      ),
    ],
  );
}
